const request = require('supertest');
const { createApp } = require('../../src/app');
const { Emergency, EmergencyAssignment, User, Volunteer } = require('../../src/models');
const { useTestDatabase } = require('../helpers/db');
const { createVolunteer, createOpenEmergency, dispatch } = require('../helpers/scenario');

const base = '/api/v1/volunteers/me/emergencies';

describe('Volunteer emergency response', () => {
  useTestDatabase();
  const app = createApp();

  async function dispatched(options) {
    const responder = await createVolunteer({ name: 'Ravi Kale' });
    const { reporter, emergency } = await createOpenEmergency();
    const assignment = await dispatch(emergency, responder.volunteer, options);
    return { responder, reporter, emergency, assignment };
  }

  it('lists the active assignment with reporter contact while responding', async () => {
    const { responder, reporter } = await dispatched();
    await User.updateOne({ _id: reporter.user._id }, { phone: '+91 90000 00000' });

    const res = await request(app).get(base).set('Authorization', responder.auth);

    expect(res.status).toBe(200);
    expect(res.body.data.total).toBe(1);
    expect(res.body.data.items[0]).toMatchObject({
      status: 'ASSIGNED',
      assignment: { status: 'PENDING', estimatedDurationSeconds: 240 },
      reporter: { phone: '+91 90000 00000', medicalProfile: null },
    });
  });

  it('shares the medical profile only with the reporter’s consent', async () => {
    const { responder, reporter, emergency } = await dispatched();
    await User.updateOne(
      { _id: reporter.user._id },
      { medicalProfile: { bloodGroup: 'B+', allergies: 'Penicillin', shareWithResponders: true } },
    );

    const res = await request(app)
      .get(`${base}/${emergency.id}`)
      .set('Authorization', responder.auth);

    expect(res.body.data.reporter.medicalProfile).toMatchObject({
      bloodGroup: 'B+',
      allergies: 'Penicillin',
    });
  });

  it('accept -> BUSY, emergency ACCEPTED (atomic)', async () => {
    const { responder, emergency, assignment } = await dispatched();

    const res = await request(app)
      .post(`${base}/${emergency.id}/accept`)
      .set('Authorization', responder.auth);

    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({ status: 'ACCEPTED', assignment: { status: 'ACCEPTED' } });
    expect(await Volunteer.findById(responder.volunteer._id)).toMatchObject({ status: 'BUSY' });
    expect(await EmergencyAssignment.findById(assignment._id)).toMatchObject({
      status: 'ACCEPTED',
      isActive: true,
    });
  });

  it('accepting twice is idempotent for the same volunteer', async () => {
    const { responder, emergency } = await dispatched();

    const results = await Promise.all([
      request(app).post(`${base}/${emergency.id}/accept`).set('Authorization', responder.auth),
      request(app).post(`${base}/${emergency.id}/accept`).set('Authorization', responder.auth),
    ]);

    const statuses = results.map((r) => r.status).sort();
    expect(statuses[0]).toBe(200);
    expect(results.some((r) => r.status === 200 && r.body.data.status === 'ACCEPTED')).toBe(true);
    expect(await Volunteer.findById(responder.volunteer._id)).toMatchObject({ status: 'BUSY' });
    expect(
      (await Emergency.findById(emergency._id)).statusHistory.filter(
        (h) => h.status === 'ACCEPTED',
      ),
    ).toHaveLength(1);
  });

  it('cannot accept after the 2-minute window, even before the scheduler runs', async () => {
    const { responder, emergency } = await dispatched({ expiresInMs: -1000 });

    const res = await request(app)
      .post(`${base}/${emergency.id}/accept`)
      .set('Authorization', responder.auth);

    expect(res.status).toBe(410);
    expect(res.body.code).toBe('ASSIGNMENT_EXPIRED');
    expect(await Volunteer.findById(responder.volunteer._id)).toMatchObject({ status: 'ACTIVE' });
    expect(await Emergency.findById(emergency._id)).toMatchObject({ status: 'ASSIGNED' });
  });

  it('a volunteer cannot act on another volunteer’s assignment', async () => {
    const { emergency } = await dispatched();
    const intruder = await createVolunteer();

    const view = await request(app)
      .get(`${base}/${emergency.id}`)
      .set('Authorization', intruder.auth);
    const accept = await request(app)
      .post(`${base}/${emergency.id}/accept`)
      .set('Authorization', intruder.auth);
    const resolve = await request(app)
      .post(`${base}/${emergency.id}/resolve`)
      .set('Authorization', intruder.auth)
      .send({ resolutionNote: 'Not mine' });

    expect([view.status, accept.status, resolve.status]).toEqual([404, 404, 404]);
  });

  it('unverified volunteers cannot accept', async () => {
    const { responder, emergency } = await dispatched();
    await Volunteer.updateOne({ _id: responder.volunteer._id }, { verificationStatus: 'REJECTED' });

    const res = await request(app)
      .post(`${base}/${emergency.id}/accept`)
      .set('Authorization', responder.auth);

    expect(res.body.code).toBe('VOLUNTEER_NOT_VERIFIED');
  });

  it('decline releases the volunteer and returns the emergency to the engine', async () => {
    const { responder, emergency, assignment } = await dispatched();

    const res = await request(app)
      .post(`${base}/${emergency.id}/decline`)
      .set('Authorization', responder.auth)
      .send({ reason: 'Too far' });

    expect(res.status).toBe(200);
    expect(await EmergencyAssignment.findById(assignment._id)).toMatchObject({
      status: 'DECLINED',
      isActive: false,
    });
    expect(await Volunteer.findById(responder.volunteer._id)).toMatchObject({
      status: 'ACTIVE',
      currentAssignmentId: null,
      currentEmergencyId: null,
    });
    const fresh = await Emergency.findById(emergency._id);
    expect(fresh.status).toBe('ASSIGNING');
    expect(fresh.excludedVolunteerIds.map(String)).toEqual([responder.volunteer.id]);
  });

  it('start -> IN_PROGRESS, resolve -> RESOLVED and the volunteer is ACTIVE again', async () => {
    const { responder, emergency, assignment } = await dispatched();
    await request(app).post(`${base}/${emergency.id}/accept`).set('Authorization', responder.auth);

    const started = await request(app)
      .post(`${base}/${emergency.id}/start`)
      .set('Authorization', responder.auth);
    const resolved = await request(app)
      .post(`${base}/${emergency.id}/resolve`)
      .set('Authorization', responder.auth)
      .send({ resolutionNote: 'Gave first aid, escorted to camp 4' });

    expect(started.body.data.status).toBe('IN_PROGRESS');
    expect(resolved.status).toBe(200);
    expect(resolved.body.data).toMatchObject({
      status: 'RESOLVED',
      isOpen: false,
      resolutionNote: 'Gave first aid, escorted to camp 4',
      assignment: { status: 'COMPLETED' },
      reporter: { phone: null },
    });
    expect(await Volunteer.findById(responder.volunteer._id)).toMatchObject({
      status: 'ACTIVE',
      currentAssignmentId: null,
      currentEmergencyId: null,
    });
    expect(await EmergencyAssignment.findById(assignment._id)).toMatchObject({ isActive: false });

    const history = await request(app)
      .get(base)
      .query({ scope: 'HISTORY' })
      .set('Authorization', responder.auth);
    expect(history.body.data.items.map((i) => i.id)).toEqual([emergency.id]);
  });

  it('resolving requires a note and an accepted emergency', async () => {
    const { responder, emergency } = await dispatched();

    const noNote = await request(app)
      .post(`${base}/${emergency.id}/resolve`)
      .set('Authorization', responder.auth)
      .send({});
    const notAccepted = await request(app)
      .post(`${base}/${emergency.id}/resolve`)
      .set('Authorization', responder.auth)
      .send({ resolutionNote: 'Done' });

    expect(noNote.status).toBe(400);
    expect(notAccepted.status).toBe(409);
  });
});
