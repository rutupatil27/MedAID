const request = require('supertest');
const { createApp } = require('../../src/app');
const {
  Emergency,
  EmergencyAssignment,
  MedicalCamp,
  RefreshToken,
  User,
  Volunteer,
  VolunteerDocument,
} = require('../../src/models');
const { setDocumentStorage } = require('../../src/integrations/cloudinary/documentStorage');
const { useTestDatabase } = require('../helpers/db');
const { createAccount } = require('../helpers/factories');
const { CENTER, createVolunteer, createOpenEmergency, dispatch } = require('../helpers/scenario');
const { whenIdle } = require('../../src/services/assignment/assignment.service');

const HOUR = 3600 * 1000;

describe('Admin API', () => {
  useTestDatabase();
  const app = createApp();
  let admin;

  beforeEach(async () => {
    admin = await createAccount({ role: 'ADMIN' });
    setDocumentStorage({
      upload: async () => ({ publicId: 'p', resourceType: 'image', deliveryType: 'authenticated' }),
      signedUrl: ({ publicId }) => `https://signed.example/${publicId}?expires=300`,
      remove: async () => {},
    });
  });

  const as = (method, url) =>
    request(app)[method](`/api/v1/admin${url}`).set('Authorization', admin.auth);

  it('is closed to USER and VOLUNTEER roles', async () => {
    const user = await createAccount();
    const volunteer = await createVolunteer();

    for (const auth of [user.auth, volunteer.auth]) {
      const res = await request(app).get('/api/v1/admin/dashboard').set('Authorization', auth);
      expect(res.status).toBe(403);
    }
  });

  describe('volunteer onboarding', () => {
    it('creates a volunteer with a one-time temporary password that must be changed', async () => {
      const res = await as('post', '/volunteers').send({
        name: 'Ravi Kale',
        email: 'ravi@example.com',
        username: 'ravi_k',
      });

      expect(res.status).toBe(201);
      const { volunteer, temporaryPassword } = res.body.data;
      expect(temporaryPassword).toMatch(/^(?=.*[A-Za-z])(?=.*\d).{12}$/);
      expect(volunteer).toMatchObject({ verificationStatus: 'NOT_SUBMITTED', status: 'OFFLINE' });

      const login = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: 'ravi_k', password: temporaryPassword });
      expect(login.body.data.user).toMatchObject({ role: 'VOLUNTEER', mustChangePassword: true });

      const blocked = await request(app)
        .get('/api/v1/volunteers/me')
        .set('Authorization', `Bearer ${login.body.data.accessToken}`);
      expect(blocked.body.code).toBe('PASSWORD_CHANGE_REQUIRED');
    });

    it('rejects duplicate accounts', async () => {
      await createAccount({ email: 'taken@example.com' });

      const res = await as('post', '/volunteers').send({
        name: 'Dup',
        email: 'taken@example.com',
        username: 'fresh_name',
      });

      expect(res.status).toBe(409);
      expect(await Volunteer.countDocuments()).toBe(0);
    });

    it('verifies a pending volunteer and approves their documents', async () => {
      const { volunteer } = await createVolunteer({
        verificationStatus: 'PENDING',
        status: 'OFFLINE',
      });
      await VolunteerDocument.create({
        volunteerId: volunteer._id,
        documentType: 'ID_PROOF',
        publicId: 'id-1',
        resourceType: 'image',
        mimeType: 'image/png',
        sizeBytes: 10,
      });

      const docs = await as('get', `/volunteers/${volunteer.id}/documents`);
      const verified = await as('post', `/volunteers/${volunteer.id}/verify`).send({});

      expect(docs.body.data[0]).toMatchObject({
        documentType: 'ID_PROOF',
        url: 'https://signed.example/id-1?expires=300',
      });
      expect(docs.body.data[0].publicId).toBeUndefined();
      expect(verified.body.data.verificationStatus).toBe('APPROVED');
      expect((await VolunteerDocument.findOne()).status).toBe('APPROVED');
      const fresh = await Volunteer.findById(volunteer._id);
      expect(fresh.verifiedBy.toString()).toBe(admin.user.id);
    });

    it('rejects with a mandatory reason, and only volunteers under review', async () => {
      const pending = await createVolunteer({ verificationStatus: 'PENDING', status: 'OFFLINE' });
      const approved = await createVolunteer();

      const noReason = await as('post', `/volunteers/${pending.volunteer.id}/reject`).send({});
      const rejected = await as('post', `/volunteers/${pending.volunteer.id}/reject`).send({
        reason: 'ID photo unreadable',
      });
      const notPending = await as('post', `/volunteers/${approved.volunteer.id}/verify`).send({});

      expect(noReason.status).toBe(400);
      expect(rejected.body.data).toMatchObject({
        verificationStatus: 'REJECTED',
        rejectionReason: 'ID photo unreadable',
      });
      expect(notPending.status).toBe(409);
    });

    it('filters and searches volunteers', async () => {
      await createVolunteer({
        name: 'Meera Joshi',
        verificationStatus: 'PENDING',
        status: 'OFFLINE',
      });
      await createVolunteer({ name: 'Arjun Rao' });

      const pending = await as('get', '/volunteers').query({ verificationStatus: 'PENDING' });
      const search = await as('get', '/volunteers').query({ search: 'arjun' });

      expect(pending.body.data.items.map((v) => v.user.name)).toEqual(['Meera Joshi']);
      expect(search.body.data.items.map((v) => v.user.name)).toEqual(['Arjun Rao']);
    });
  });

  describe('suspension', () => {
    it('suspending a BUSY volunteer signs them out and hands the emergency back', async () => {
      const responder = await createVolunteer();
      const { emergency } = await createOpenEmergency();
      const assignment = await dispatch(emergency, responder.volunteer);
      await Emergency.updateOne({ _id: emergency._id }, { status: 'ACCEPTED' });
      await EmergencyAssignment.updateOne({ _id: assignment._id }, { status: 'ACCEPTED' });
      await Volunteer.updateOne({ _id: responder.volunteer._id }, { status: 'BUSY' });

      const res = await as('patch', `/volunteers/${responder.volunteer.id}/status`).send({
        accountStatus: 'SUSPENDED',
      });

      expect(res.status).toBe(200);
      expect(res.body.data).toMatchObject({
        status: 'OFFLINE',
        user: { accountStatus: 'SUSPENDED' },
      });
      expect(
        await RefreshToken.countDocuments({ userId: responder.user._id, revokedAt: null }),
      ).toBe(0);
      await whenIdle();
      const fresh = await Emergency.findById(emergency._id);
      // Handed straight back to the engine; nobody else is on duty, so admins see it waiting.
      expect(fresh).toMatchObject({
        status: 'UNASSIGNED',
        isOpen: true,
        assignedVolunteerId: null,
      });
      expect(fresh.excludedVolunteerIds.map(String)).toContain(responder.volunteer.id);
      expect(await EmergencyAssignment.findById(assignment._id)).toMatchObject({
        status: 'CANCELLED',
      });

      const me = await request(app).get('/api/v1/users/me').set('Authorization', responder.auth);
      expect(me.body.code).toBe('ACCOUNT_SUSPENDED');
    });

    it('admins can suspend users but not themselves', async () => {
      const user = await createAccount();

      const suspended = await as('patch', `/users/${user.user.id}/status`).send({
        accountStatus: 'SUSPENDED',
      });
      const self = await as('patch', `/users/${admin.user.id}/status`).send({
        accountStatus: 'SUSPENDED',
      });

      expect(suspended.body.data.accountStatus).toBe('SUSPENDED');
      expect(self.status).toBe(403);
    });
  });

  describe('medical camps', () => {
    const campBody = (overrides = {}) => ({
      name: 'Ghat Camp 4',
      address: 'Ramkund ghat',
      ...CENTER,
      services: ['First aid', 'ORS'],
      contact: { name: 'Dr. Kulkarni', phone: '0253 000000' },
      startDateTime: new Date(Date.now() - HOUR).toISOString(),
      endDateTime: new Date(Date.now() + HOUR).toISOString(),
      ...overrides,
    });

    it('creates a camp that users see, and hides it when deactivated or deleted', async () => {
      const user = await createAccount();
      const nearby = () =>
        request(app)
          .get('/api/v1/medical-camps/nearby')
          .query(CENTER)
          .set('Authorization', user.auth);

      const created = await as('post', '/medical-camps').send(campBody());
      expect(created.status).toBe(201);
      expect(created.body.data).toMatchObject({ lifecycle: 'ACTIVE_NOW', isActive: true });
      expect((await nearby()).body.data).toHaveLength(1);

      await as('patch', `/medical-camps/${created.body.data.id}`).send({ isActive: false });
      expect((await nearby()).body.data).toHaveLength(0);

      await as('delete', `/medical-camps/${created.body.data.id}`);
      expect((await MedicalCamp.findById(created.body.data.id)).isDeleted).toBe(true);
      expect((await as('get', `/medical-camps/${created.body.data.id}`)).status).toBe(404);
    });

    it('validates the validity window', async () => {
      const res = await as('post', '/medical-camps').send(
        campBody({ endDateTime: new Date(Date.now() - 2 * HOUR).toISOString() }),
      );
      const created = await as('post', '/medical-camps').send(campBody());
      const badUpdate = await as('patch', `/medical-camps/${created.body.data.id}`).send({
        endDateTime: new Date(Date.now() - 2 * HOUR).toISOString(),
      });

      expect(res.status).toBe(400);
      expect(badUpdate.status).toBe(400);
    });

    it('lists camps by lifecycle', async () => {
      await as('post', '/medical-camps').send(campBody({ name: 'Now' }));
      await as('post', '/medical-camps').send(
        campBody({
          name: 'Later',
          startDateTime: new Date(Date.now() + HOUR).toISOString(),
          endDateTime: new Date(Date.now() + 2 * HOUR).toISOString(),
        }),
      );

      const upcoming = await as('get', '/medical-camps').query({ status: 'UPCOMING' });
      const all = await as('get', '/medical-camps');

      expect(upcoming.body.data.items.map((c) => c.name)).toEqual(['Later']);
      expect(all.body.data.total).toBe(2);
    });
  });

  describe('emergency monitoring', () => {
    it('lists emergencies with reporter and assigned volunteer, and shows assignment history', async () => {
      const responder = await createVolunteer({ name: 'Ravi Kale' });
      const { emergency } = await createOpenEmergency();
      await dispatch(emergency, responder.volunteer);

      const list = await as('get', '/emergencies').query({ open: true });
      const history = await as('get', `/emergencies/${emergency.id}/assignments`);

      expect(list.body.data.items[0]).toMatchObject({
        id: emergency.id,
        status: 'ASSIGNED',
        assignedVolunteer: { name: 'Ravi Kale', status: 'ACTIVE' },
      });
      expect(history.body.data).toEqual([
        expect.objectContaining({
          status: 'PENDING',
          attemptNumber: 1,
          volunteer: expect.objectContaining({ name: 'Ravi Kale' }),
        }),
      ]);
    });

    it('admin override: resolve with a note releases the volunteer', async () => {
      const responder = await createVolunteer();
      const { emergency } = await createOpenEmergency();
      await dispatch(emergency, responder.volunteer);

      const noNote = await as('post', `/emergencies/${emergency.id}/resolve`).send({});
      const resolved = await as('post', `/emergencies/${emergency.id}/resolve`).send({
        note: 'Handled by control room',
      });
      const again = await as('post', `/emergencies/${emergency.id}/cancel`).send({ note: 'dup' });

      expect(noNote.status).toBe(400);
      expect(resolved.body.data).toMatchObject({
        status: 'RESOLVED',
        resolutionNote: 'Handled by control room',
      });
      expect(await Volunteer.findById(responder.volunteer._id)).toMatchObject({
        currentEmergencyId: null,
      });
      expect(again.status).toBe(409);
    });
  });

  it('dashboard and reports summarise the operation', async () => {
    await createVolunteer({ verificationStatus: 'PENDING', status: 'OFFLINE' });
    await createVolunteer();
    const { emergency } = await createOpenEmergency();
    await Emergency.updateOne({ _id: emergency._id }, { status: 'UNASSIGNED' });
    const resolvedCase = await createOpenEmergency();
    await Emergency.updateOne(
      { _id: resolvedCase.emergency._id },
      {
        status: 'RESOLVED',
        isOpen: false,
        attemptCount: 2,
        acceptedAt: new Date(resolvedCase.emergency.createdAt.getTime() + 60_000),
        resolvedAt: new Date(resolvedCase.emergency.createdAt.getTime() + 600_000),
      },
    );

    const dashboard = await as('get', '/dashboard');
    const report = await as('get', '/reports/summary');

    expect(dashboard.body.data).toMatchObject({
      emergencies: { open: 1, unassigned: 1 },
      volunteers: { pendingVerification: 1, byStatus: { ACTIVE: 1, OFFLINE: 1, BUSY: 0 } },
    });
    expect(report.body.data.emergencies).toMatchObject({
      total: 2,
      resolved: 1,
      reassigned: 1,
      reassignmentRate: 0.5,
      avgTimeToAcceptSeconds: 60,
      avgTimeToResolveSeconds: 600,
    });
    expect(report.body.data.perDay[0].count).toBe(2);
  });

  it('shows live locations of active volunteers only', async () => {
    await createVolunteer({ name: 'On Duty' });
    await createVolunteer({ name: 'Off Duty', status: 'OFFLINE' });

    const res = await as('get', '/volunteers/locations');

    expect(res.body.data.map((v) => v.name)).toEqual(['On Duty']);
    expect(res.body.data[0].location).toMatchObject({ ...CENTER, isStale: false });
  });

  it('lists users with filters', async () => {
    await createAccount({ name: 'Plain User' });

    const res = await as('get', '/users').query({ role: 'USER' });

    expect(res.body.data.items.map((u) => u.name)).toEqual(['Plain User']);
    expect(res.body.data.items[0].passwordHash).toBeUndefined();
    expect(await User.countDocuments()).toBeGreaterThan(1);
  });
});
