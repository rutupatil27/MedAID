const request = require('supertest');
const { createApp } = require('../../src/app');
const { Emergency, EmergencyAssignment, User, Volunteer } = require('../../src/models');
const engine = require('../../src/services/assignment/assignment.service');
const notificationService = require('../../src/services/notification/notification.service');
const { setRoutingService, createRoutingService } = require('../../src/integrations/routing');
const { useTestDatabase } = require('../helpers/db');
const { createAccount } = require('../helpers/factories');
const { CENTER, north, createVolunteer, createOpenEmergency } = require('../helpers/scenario');

const STALE = 10 * 60 * 1000; // older than the 5-minute threshold

describe('Emergency assignment engine', () => {
  useTestDatabase();
  const app = createApp();
  let adminAlerts;

  beforeEach(() => {
    setRoutingService(createRoutingService({ orsApiKey: '', profile: 'foot-walking' }));
    adminAlerts = jest.spyOn(notificationService, 'notifyAdmins');
  });

  afterEach(() => jest.restoreAllMocks());

  const assignedTo = async (emergency) =>
    (await Emergency.findById(emergency._id)).assignedVolunteerId?.toString();

  async function sosAndAssign(reporter, location = CENTER) {
    const res = await request(app)
      .post('/api/v1/emergencies')
      .set('Authorization', reporter.auth)
      .send(location);
    await engine.whenIdle();
    return Emergency.findById(res.body.data.id);
  }

  async function expireNow(emergency) {
    await EmergencyAssignment.updateMany(
      { emergencyId: emergency._id, status: 'PENDING' },
      { $set: { expiresAt: new Date(Date.now() - 1000) } },
    );
    await engine.runAssignmentScan();
    await engine.whenIdle();
  }

  // ---- Critical cases from 24_TESTING_STRATEGY.md ----------------------------

  it('1. one active verified volunteer is assigned (PENDING, 2-minute window)', async () => {
    const volunteer = await createVolunteer();
    const reporter = await createAccount();

    const emergency = await sosAndAssign(reporter);

    expect(emergency.status).toBe('ASSIGNED');
    expect(emergency.assignedVolunteerId.toString()).toBe(volunteer.volunteer.id);
    const assignment = await EmergencyAssignment.findOne({ emergencyId: emergency._id });
    expect(assignment).toMatchObject({
      status: 'PENDING',
      attemptNumber: 1,
      distanceSource: 'FALLBACK',
    });
    expect(assignment.expiresAt - assignment.dispatchedAt).toBe(120000);
    // Reserved but still ACTIVE until acceptance.
    expect(await Volunteer.findById(volunteer.volunteer._id)).toMatchObject({
      status: 'ACTIVE',
      currentEmergencyId: emergency._id,
    });
  });

  it.each([
    ['2. BUSY', { status: 'BUSY' }],
    ['3. OFFLINE', { status: 'OFFLINE' }],
    ['4. unverified (PENDING)', { verificationStatus: 'PENDING' }],
    ['4b. REJECTED', { verificationStatus: 'REJECTED' }],
    ['5. missing location', { location: null }],
    ['6. stale location', { locationAgeMs: STALE }],
    ['suspended account', { accountStatus: 'SUSPENDED' }],
  ])('%s nearest volunteer is skipped for an eligible farther one', async (_label, overrides) => {
    const ineligible = await createVolunteer({ location: CENTER, ...overrides });
    const eligible = await createVolunteer({ location: north(1500) });
    const reporter = await createAccount();

    const emergency = await sosAndAssign(reporter);

    expect(emergency.assignedVolunteerId.toString()).toBe(eligible.volunteer.id);
    expect(emergency.assignedVolunteerId.toString()).not.toBe(ineligible.volunteer.id);
  });

  it('7. accepting within 2 minutes makes the volunteer BUSY', async () => {
    const volunteer = await createVolunteer();
    const emergency = await sosAndAssign(await createAccount());

    const res = await request(app)
      .post(`/api/v1/volunteers/me/emergencies/${emergency.id}/accept`)
      .set('Authorization', volunteer.auth);

    expect(res.status).toBe(200);
    expect(await Volunteer.findById(volunteer.volunteer._id)).toMatchObject({ status: 'BUSY' });
    expect(await Emergency.findById(emergency._id)).toMatchObject({ status: 'ACCEPTED' });
  });

  it('8. no acceptance within 2 minutes: expired, history kept, next volunteer dispatched', async () => {
    const first = await createVolunteer({ location: CENTER });
    const second = await createVolunteer({ location: north(800) });
    const emergency = await sosAndAssign(await createAccount());
    expect(await assignedTo(emergency)).toBe(first.volunteer.id);

    await expireNow(emergency);

    const fresh = await Emergency.findById(emergency._id);
    expect(fresh).toMatchObject({ status: 'ASSIGNED', isOpen: true, attemptCount: 2 });
    expect(fresh.assignedVolunteerId.toString()).toBe(second.volunteer.id);
    expect(fresh.excludedVolunteerIds.map(String)).toEqual([first.volunteer.id]);
    const history = await EmergencyAssignment.find({ emergencyId: emergency._id }).sort({
      attemptNumber: 1,
    });
    expect(history.map((a) => [a.attemptNumber, a.status])).toEqual([
      [1, 'EXPIRED'],
      [2, 'PENDING'],
    ]);
    expect(await Volunteer.findById(first.volunteer._id)).toMatchObject({
      status: 'ACTIVE',
      currentEmergencyId: null,
    });
    expect(adminAlerts).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'ASSIGNMENT_EXPIRED' }),
    );

    // The expired volunteer can no longer accept.
    const late = await request(app)
      .post(`/api/v1/volunteers/me/emergencies/${emergency.id}/accept`)
      .set('Authorization', first.auth);
    expect(late.body.code).toBe('ASSIGNMENT_EXPIRED');
  });

  it('9. two volunteers accepting simultaneously: only the dispatched one succeeds', async () => {
    const dispatched = await createVolunteer({ location: CENTER });
    const other = await createVolunteer({ location: north(900) });
    const emergency = await sosAndAssign(await createAccount());

    const [a, b] = await Promise.all([
      request(app)
        .post(`/api/v1/volunteers/me/emergencies/${emergency.id}/accept`)
        .set('Authorization', dispatched.auth),
      request(app)
        .post(`/api/v1/volunteers/me/emergencies/${emergency.id}/accept`)
        .set('Authorization', other.auth),
    ]);

    expect(a.status).toBe(200);
    expect(b.status).toBe(404);
    expect(await Volunteer.findById(other.volunteer._id)).toMatchObject({ status: 'ACTIVE' });
  });

  it('9b. accept racing the timeout: exactly one outcome wins', async () => {
    for (let round = 0; round < 5; round += 1) {
      const volunteer = await createVolunteer({ location: CENTER });
      await createVolunteer({ location: north(700) });
      const emergency = await sosAndAssign(await createAccount());
      await EmergencyAssignment.updateOne(
        { emergencyId: emergency._id, status: 'PENDING' },
        { $set: { expiresAt: new Date(Date.now() + 5) } },
      );
      await new Promise((r) => setTimeout(r, 5));

      const [accept] = await Promise.all([
        request(app)
          .post(`/api/v1/volunteers/me/emergencies/${emergency.id}/accept`)
          .set('Authorization', volunteer.auth),
        engine.runAssignmentScan(),
      ]);
      await engine.whenIdle();

      const first = await EmergencyAssignment.findOne({
        emergencyId: emergency._id,
        attemptNumber: 1,
      });
      const vol = await Volunteer.findById(volunteer.volunteer._id);
      if (accept.status === 200) {
        expect(first.status).toBe('ACCEPTED');
        expect(vol.status).toBe('BUSY');
      } else {
        expect(first.status).toBe('EXPIRED');
        expect(vol.status).toBe('ACTIVE');
        expect(vol.currentEmergencyId?.toString()).not.toBe(emergency.id);
      }
      await Emergency.deleteMany({});
      await EmergencyAssignment.deleteMany({});
      await Volunteer.deleteMany({});
    }
  });

  it('10. resolution returns the volunteer to ACTIVE', async () => {
    const volunteer = await createVolunteer();
    const emergency = await sosAndAssign(await createAccount());
    const base = `/api/v1/volunteers/me/emergencies/${emergency.id}`;

    await request(app).post(`${base}/accept`).set('Authorization', volunteer.auth);
    const res = await request(app)
      .post(`${base}/resolve`)
      .set('Authorization', volunteer.auth)
      .send({ resolutionNote: 'Treated at the ghat' });

    expect(res.body.data.status).toBe('RESOLVED');
    expect(await Volunteer.findById(volunteer.volunteer._id)).toMatchObject({
      status: 'ACTIVE',
      currentEmergencyId: null,
    });
  });

  it('11. no eligible volunteer: UNASSIGNED (never reported as assigned) and admins notified', async () => {
    await createVolunteer({ status: 'OFFLINE' });
    const emergency = await sosAndAssign(await createAccount());

    expect(emergency).toMatchObject({
      status: 'UNASSIGNED',
      isOpen: true,
      assignedVolunteerId: null,
    });
    expect(adminAlerts).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'EMERGENCY_UNASSIGNED',
        data: expect.objectContaining({ reason: 'NO_ELIGIBLE_VOLUNTEER' }),
      }),
    );
  });

  it('12. a volunteer who goes OFFLINE receives no new automatic assignment', async () => {
    const volunteer = await createVolunteer();
    await request(app)
      .patch('/api/v1/volunteers/me/status')
      .set('Authorization', volunteer.auth)
      .send({ status: 'OFFLINE' });

    const emergency = await sosAndAssign(await createAccount());

    expect(emergency.status).toBe('UNASSIGNED');
    expect(await EmergencyAssignment.countDocuments()).toBe(0);
  });

  // ---- Further safety properties ---------------------------------------------

  it('two simultaneous SOS alerts never reserve the same volunteer', async () => {
    await createVolunteer();
    const [a, b] = [await createAccount(), await createAccount()];

    await Promise.all([
      request(app).post('/api/v1/emergencies').set('Authorization', a.auth).send(CENTER),
      request(app).post('/api/v1/emergencies').set('Authorization', b.auth).send(north(20)),
    ]);
    await engine.whenIdle();

    const statuses = (await Emergency.find()).map((e) => e.status).sort();
    expect(statuses).toEqual(['ASSIGNED', 'UNASSIGNED']);
    expect(await EmergencyAssignment.countDocuments({ isActive: true })).toBe(1);
  });

  it('ranks by road travel time when routing is available', async () => {
    const straightNearest = await createVolunteer({ location: north(200) });
    const fastestByRoad = await createVolunteer({ location: north(900) });
    setRoutingService({
      async matrix(origins) {
        return origins.map((o) => ({
          distanceMeters: 1000,
          durationSeconds: o.latitude > CENTER.latitude + 0.005 ? 120 : 900,
          source: 'ROUTING',
        }));
      },
    });

    const emergency = await sosAndAssign(await createAccount());

    expect(await assignedTo(emergency)).toBe(fastestByRoad.volunteer.id);
    expect(await assignedTo(emergency)).not.toBe(straightNearest.volunteer.id);
    expect((await EmergencyAssignment.findOne()).distanceSource).toBe('ROUTING');
  });

  it('falls back to straight-line distance when routing fails', async () => {
    const volunteer = await createVolunteer();
    const failing = {
      name: 'down',
      matrix: () => Promise.reject(new Error('ORS down')),
      route: () => Promise.reject(new Error('ORS down')),
    };
    const {
      withFallback,
      createRoutingService: create,
    } = require('../../src/integrations/routing');
    setRoutingService(withFallback(failing, create({ orsApiKey: '', profile: 'foot-walking' })));

    const emergency = await sosAndAssign(await createAccount());

    expect(await assignedTo(emergency)).toBe(volunteer.volunteer.id);
    expect((await EmergencyAssignment.findOne()).distanceSource).toBe('FALLBACK');
  });

  it('SOS without a location is escalated to admins immediately', async () => {
    await createVolunteer();
    const reporter = await createAccount();

    const res = await request(app)
      .post('/api/v1/emergencies')
      .set('Authorization', reporter.auth)
      .send({});
    await engine.whenIdle();

    expect((await Emergency.findById(res.body.data.id)).status).toBe('UNASSIGNED');
    expect(adminAlerts).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ reason: 'NO_LOCATION' }) }),
    );
  });

  it('declining dispatches the next candidate straight away', async () => {
    const first = await createVolunteer({ location: CENTER });
    const second = await createVolunteer({ location: north(600) });
    const emergency = await sosAndAssign(await createAccount());

    await request(app)
      .post(`/api/v1/volunteers/me/emergencies/${emergency.id}/decline`)
      .set('Authorization', first.auth)
      .send({});
    await engine.whenIdle();

    expect(await assignedTo(emergency)).toBe(second.volunteer.id);
  });

  it('a previously excluded volunteer is retried only when nobody else is available', async () => {
    const only = await createVolunteer();
    const emergency = await sosAndAssign(await createAccount());

    await expireNow(emergency);

    const fresh = await Emergency.findById(emergency._id);
    expect(fresh.assignedVolunteerId.toString()).toBe(only.volunteer.id);
    expect(fresh.attemptCount).toBe(2);
  });

  it('going OFFLINE with a pending assignment hands it on immediately', async () => {
    const first = await createVolunteer({ location: CENTER });
    const second = await createVolunteer({ location: north(500) });
    const emergency = await sosAndAssign(await createAccount());

    await request(app)
      .patch('/api/v1/volunteers/me/status')
      .set('Authorization', first.auth)
      .send({ status: 'OFFLINE' });
    await engine.whenIdle();

    expect(await assignedTo(emergency)).toBe(second.volunteer.id);
    const expired = await EmergencyAssignment.findOne({ volunteerId: first.volunteer._id });
    expect(expired).toMatchObject({ status: 'EXPIRED', endReason: 'VOLUNTEER_UNAVAILABLE' });
  });

  it('waiting emergencies are served when a volunteer becomes ACTIVE', async () => {
    const emergency = await sosAndAssign(await createAccount());
    expect(emergency.status).toBe('UNASSIGNED');
    const volunteer = await createVolunteer({ status: 'OFFLINE', location: null });

    await request(app)
      .patch('/api/v1/volunteers/me/status')
      .set('Authorization', volunteer.auth)
      .send({ status: 'ACTIVE', ...north(300) });
    await engine.whenIdle();

    expect(await assignedTo(emergency)).toBe(volunteer.volunteer.id);
  });

  it('warns the volunteer shortly before the assignment expires', async () => {
    const volunteer = await createVolunteer();
    const emergency = await sosAndAssign(await createAccount());
    const notify = jest.spyOn(notificationService, 'notify');
    await EmergencyAssignment.updateOne(
      { emergencyId: emergency._id },
      { $set: { expiresAt: new Date(Date.now() + 10_000) } },
    );

    await engine.runAssignmentScan();
    await engine.runAssignmentScan();

    const warnings = notify.mock.calls.filter(([e]) => e.type === 'ASSIGNMENT_EXPIRING');
    expect(warnings).toHaveLength(1);
    expect(warnings[0][0].recipients.map(String)).toEqual([volunteer.user.id]);
  });

  it('escalates to admins after repeated timeouts', async () => {
    await createVolunteer({ location: CENTER });
    await createVolunteer({ location: north(300) });
    await createVolunteer({ location: north(600) });
    const emergency = await sosAndAssign(await createAccount());

    await expireNow(emergency);
    await expireNow(emergency);
    await expireNow(emergency);

    expect(adminAlerts).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'EMERGENCY_ESCALATED' }),
    );
  });

  it('admin can assign to a chosen eligible volunteer, and is refused an ineligible one', async () => {
    const admin = await createAccount({ role: 'ADMIN' });
    const first = await createVolunteer({ location: CENTER });
    const chosen = await createVolunteer({ location: north(1200) });
    const offline = await createVolunteer({ status: 'OFFLINE' });
    const emergency = await sosAndAssign(await createAccount());
    expect(await assignedTo(emergency)).toBe(first.volunteer.id);

    const ok = await request(app)
      .post(`/api/v1/admin/emergencies/${emergency.id}/reassign`)
      .set('Authorization', admin.auth)
      .send({ volunteerId: chosen.volunteer.id });
    expect(ok.status).toBe(200);
    expect(await assignedTo(emergency)).toBe(chosen.volunteer.id);

    const refused = await request(app)
      .post(`/api/v1/admin/emergencies/${emergency.id}/reassign`)
      .set('Authorization', admin.auth)
      .send({ volunteerId: offline.volunteer.id });
    await engine.whenIdle();
    expect(refused.body.code).toBe('VOLUNTEER_NOT_AVAILABLE');
    // The engine took over: the emergency is not stranded.
    expect(['ASSIGNED', 'UNASSIGNED']).toContain((await Emergency.findById(emergency._id)).status);
  });

  it('keeps the work per dispatch bounded however many volunteers are on duty', async () => {
    const env = require('../../src/config/env');
    await Promise.all(
      Array.from({ length: 120 }, (_, i) => createVolunteer({ location: north(10 + i * 10) })),
    );
    const matrix = jest.fn(async (origins) =>
      origins.map(() => ({ distanceMeters: 500, durationSeconds: 400, source: 'ROUTING' })),
    );
    setRoutingService({ name: 'counting', matrix, route: jest.fn() });

    const emergency = await sosAndAssign(await createAccount());

    expect(emergency.status).toBe('ASSIGNED');
    // One routing call, for at most the configured number of candidates.
    expect(matrix).toHaveBeenCalledTimes(1);
    expect(matrix.mock.calls[0][0].length).toBeLessThanOrEqual(env.assignment.maxCandidates);
  });

  it('recovers after a restart: overdue assignments expire on the first scan', async () => {
    await createVolunteer({ location: CENTER });
    await createVolunteer({ location: north(400) });
    const emergency = await sosAndAssign(await createAccount());
    await EmergencyAssignment.updateOne(
      {},
      { $set: { expiresAt: new Date(Date.now() - 60 * 60 * 1000) } },
    );

    await engine.runAssignmentScan(); // what the scheduler runs on start
    await engine.whenIdle();

    expect((await Emergency.findById(emergency._id)).attemptCount).toBe(2);
  });

  it('a cancelled emergency is never dispatched', async () => {
    await createVolunteer();
    const { emergency } = await createOpenEmergency({ status: 'CANCELLED' });
    await Emergency.updateOne({ _id: emergency._id }, { isOpen: false });

    const result = await engine.processEmergency(emergency._id);

    expect(result.outcome).toBe('SKIPPED');
    expect(await EmergencyAssignment.countDocuments()).toBe(0);
    expect(await User.countDocuments()).toBeGreaterThan(0);
  });
});
