const request = require('supertest');
const { createApp } = require('../../src/app');
const { Emergency, EmergencyAssignment, Volunteer } = require('../../src/models');
const { useTestDatabase } = require('../helpers/db');
const { createAccount } = require('../helpers/factories');
const { whenIdle } = require('../../src/services/assignment/assignment.service');

const sos = (app, auth, body = { latitude: 20.0086, longitude: 73.7925, accuracy: 12 }) =>
  request(app).post('/api/v1/emergencies').set('Authorization', auth).send(body);

describe('User emergencies (SOS)', () => {
  useTestDatabase();
  const app = createApp();

  it('creates an alert with location, alert number and timeline', async () => {
    const { auth } = await createAccount();

    const res = await sos(app, auth);

    expect(res.status).toBe(201);
    expect(res.body.data).toMatchObject({
      status: 'CREATED',
      isOpen: true,
      location: { latitude: 20.0086, longitude: 73.7925 },
      locationAccuracy: 12,
      responder: null,
    });
    expect(res.body.data.alertNumber).toMatch(/^MED-\d{8}-\d{4}$/);
    expect(res.body.data.timeline).toEqual([
      { status: 'CREATED', at: expect.any(String), reason: null },
    ]);
  });

  it('allows SOS without a location fix (OQ-15)', async () => {
    const { auth } = await createAccount();

    const res = await sos(app, auth, {});

    expect(res.status).toBe(201);
    expect(res.body.data.location).toBeNull();
  });

  it('rejects half a coordinate pair', async () => {
    const { auth } = await createAccount();

    const res = await sos(app, auth, { latitude: 20 });

    expect(res.status).toBe(400);
  });

  it('is idempotent: repeated SOS returns the same open emergency', async () => {
    const { auth } = await createAccount();

    const first = await sos(app, auth).set('Idempotency-Key', 'sos-attempt-0001');
    const retry = await sos(app, auth).set('Idempotency-Key', 'sos-attempt-0001');
    const secondTap = await sos(app, auth).set('Idempotency-Key', 'sos-attempt-0002');

    expect(first.status).toBe(201);
    expect(retry.status).toBe(200);
    expect(secondTap.status).toBe(200);
    expect(new Set([first.body.data.id, retry.body.data.id, secondTap.body.data.id]).size).toBe(1);
    expect(await Emergency.countDocuments()).toBe(1);
  });

  it('handles simultaneous SOS requests from one user safely', async () => {
    const { auth } = await createAccount();

    const results = await Promise.all([sos(app, auth), sos(app, auth), sos(app, auth)]);

    expect(results.every((r) => [200, 201].includes(r.status))).toBe(true);
    expect(new Set(results.map((r) => r.body.data.id)).size).toBe(1);
    expect(await Emergency.countDocuments()).toBe(1);
  });

  it('lists only the caller’s emergencies and hides others (404)', async () => {
    const alice = await createAccount();
    const bob = await createAccount();
    const mine = await sos(app, alice.auth);
    await sos(app, bob.auth);

    const list = await request(app).get('/api/v1/emergencies/my').set('Authorization', alice.auth);
    const others = await request(app)
      .get(`/api/v1/emergencies/${mine.body.data.id}`)
      .set('Authorization', bob.auth);

    expect(list.body.data.total).toBe(1);
    expect(list.body.data.items[0].id).toBe(mine.body.data.id);
    expect(others.status).toBe(404);
  });

  it('cancels an open emergency and releases a BUSY volunteer back to ACTIVE', async () => {
    const { auth, user } = await createAccount();
    const created = await sos(app, auth);
    await whenIdle(); // no volunteers yet: the engine marks it UNASSIGNED
    const volunteerAccount = await createAccount({ role: 'VOLUNTEER' });
    const volunteer = await Volunteer.create({
      userId: volunteerAccount.user._id,
      verificationStatus: 'APPROVED',
      status: 'BUSY',
      currentEmergencyId: created.body.data.id,
    });
    const assignment = await EmergencyAssignment.create({
      emergencyId: created.body.data.id,
      volunteerId: volunteer._id,
      attemptNumber: 1,
      status: 'ACCEPTED',
      dispatchedAt: new Date(),
      expiresAt: new Date(Date.now() + 120000),
    });
    await Emergency.updateOne(
      { _id: created.body.data.id },
      {
        status: 'ACCEPTED',
        assignedVolunteerId: volunteer._id,
        currentAssignmentId: assignment._id,
      },
    );
    await volunteer.updateOne({ currentAssignmentId: assignment._id });

    const res = await request(app)
      .post(`/api/v1/emergencies/${created.body.data.id}/cancel`)
      .set('Authorization', auth)
      .send({ reason: 'Feeling better' });

    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({ status: 'CANCELLED', isOpen: false });
    const freed = await Volunteer.findById(volunteer._id);
    expect(freed).toMatchObject({
      status: 'ACTIVE',
      currentEmergencyId: null,
      currentAssignmentId: null,
    });
    expect(await EmergencyAssignment.findById(assignment._id)).toMatchObject({
      status: 'CANCELLED',
      isActive: false,
    });
    const stored = await Emergency.findById(created.body.data.id);
    expect(stored.cancelledBy.toString()).toBe(user.id);

    // After cancelling, the user can raise a new SOS.
    expect((await sos(app, auth)).status).toBe(201);
  });

  it('refuses to cancel a closed emergency', async () => {
    const { auth } = await createAccount();
    const created = await sos(app, auth);
    await request(app)
      .post(`/api/v1/emergencies/${created.body.data.id}/cancel`)
      .set('Authorization', auth)
      .send({});

    const again = await request(app)
      .post(`/api/v1/emergencies/${created.body.data.id}/cancel`)
      .set('Authorization', auth)
      .send({});

    expect(again.status).toBe(409);
  });

  it('only USER accounts can raise SOS', async () => {
    const { auth } = await createAccount({ role: 'ADMIN' });

    const res = await sos(app, auth);

    expect(res.status).toBe(403);
  });
});
