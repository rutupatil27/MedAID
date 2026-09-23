const request = require('supertest');
const { createApp } = require('../../src/app');
const { DeviceToken, Notification, User } = require('../../src/models');
const engine = require('../../src/services/assignment/assignment.service');
const notificationService = require('../../src/services/notification/notification.service');
const { TEMPLATES } = require('../../src/services/notification/templates');
const { setPushProvider } = require('../../src/integrations/firebase/pushProvider');
const { setRoutingService, createRoutingService } = require('../../src/integrations/routing');
const { useTestDatabase } = require('../helpers/db');
const { createAccount } = require('../helpers/factories');
const { CENTER, createVolunteer } = require('../helpers/scenario');

const TOKEN_A = `fcm-token-a:${'A'.repeat(40)}`;
const TOKEN_B = `fcm-token-b:${'B'.repeat(40)}`;

/** Records pushes instead of calling Firebase. */
function fakePush({ invalid = [], fail = false } = {}) {
  const sent = [];
  return {
    sent,
    provider: {
      name: 'fake',
      async send(tokens, message) {
        if (fail) throw new Error('FCM unavailable');
        sent.push({ tokens, ...message });
        return { invalidTokens: tokens.filter((t) => invalid.includes(t)) };
      },
    },
  };
}

describe('Notifications', () => {
  useTestDatabase();
  const app = createApp();
  let push;

  beforeEach(() => {
    push = fakePush();
    setPushProvider(push.provider);
    setRoutingService(createRoutingService({ orsApiKey: '', profile: 'foot-walking' }));
  });

  const api = (auth) => ({
    get: (path) => request(app).get(`/api/v1${path}`).set('Authorization', auth),
    post: (path, body) => request(app).post(`/api/v1${path}`).set('Authorization', auth).send(body),
    patch: (path, body) =>
      request(app).patch(`/api/v1${path}`).set('Authorization', auth).send(body),
    delete: (path) => request(app).delete(`/api/v1${path}`).set('Authorization', auth),
  });

  async function settle() {
    await engine.whenIdle();
    await notificationService.whenIdle();
  }

  async function sos(reporter, body = CENTER) {
    const res = await api(reporter.auth).post('/emergencies', body);
    await settle();
    return res;
  }

  describe('persistence and localization', () => {
    it('stores one record per recipient in their language, for the reporter and the admins', async () => {
      const admin = await createAccount({ role: 'ADMIN', preferredLanguage: 'mr' });
      const reporter = await createAccount({ preferredLanguage: 'hi' });

      await sos(reporter);

      const mine = await api(reporter.auth).get('/notifications');
      expect(mine.status).toBe(200);
      const created = mine.body.data.items.find((n) => n.type === 'EMERGENCY_CREATED');
      expect(created).toMatchObject({
        title: TEMPLATES.EMERGENCY_CREATED.USER.title.hi,
        isRead: false,
        data: { emergencyId: expect.any(String) },
      });
      // No volunteer on duty: the reporter is also told help is still being sought.
      expect(mine.body.data.items.map((n) => n.type)).toContain('EMERGENCY_UNASSIGNED');

      const adminInbox = await api(admin.auth).get('/notifications');
      const adminCreated = adminInbox.body.data.items.find((n) => n.type === 'EMERGENCY_CREATED');
      expect(adminCreated.title).toBe(TEMPLATES.EMERGENCY_CREATED.ADMIN.title.mr);
    });

    it('delivers the whole dispatch cycle to the right audiences', async () => {
      await createAccount({ role: 'ADMIN' });
      const volunteer = await createVolunteer();
      const reporter = await createAccount();

      const created = await sos(reporter);
      const id = created.body.data.id;
      await api(volunteer.auth).post(`/volunteers/me/emergencies/${id}/accept`);
      await api(volunteer.auth).post(`/volunteers/me/emergencies/${id}/resolve`, {
        resolutionNote: 'Gave water and ORS',
      });
      await settle();

      const typesFor = async (userId) =>
        (await Notification.find({ recipientUserId: userId }).sort({ createdAt: 1, _id: 1 })).map(
          (n) => n.type,
        );
      expect(await typesFor(reporter.user._id)).toEqual([
        'EMERGENCY_CREATED',
        'EMERGENCY_ASSIGNED',
        'EMERGENCY_ACCEPTED',
        'EMERGENCY_RESOLVED',
      ]);
      expect(await typesFor(volunteer.user._id)).toEqual(['ASSIGNMENT_NEW']);
    });

    it('suspended admins receive no admin alerts', async () => {
      const active = await createAccount({ role: 'ADMIN' });
      const suspended = await createAccount({ role: 'ADMIN', accountStatus: 'SUSPENDED' });

      await sos(await createAccount());

      expect(
        await Notification.countDocuments({ recipientUserId: active.user._id }),
      ).toBeGreaterThan(0);
      expect(await Notification.countDocuments({ recipientUserId: suspended.user._id })).toBe(0);
    });
  });

  describe('payload privacy (doc 19)', () => {
    it('stores and pushes IDs and event types only, never personal or medical details', async () => {
      await createAccount({ role: 'ADMIN' });
      const volunteer = await createVolunteer({ name: 'Ravi Kale' });
      const reporter = await createAccount({ name: 'Asha Patil' });
      await User.updateOne(
        { _id: reporter.user._id },
        {
          phone: '+91 90000 00000',
          medicalProfile: { bloodGroup: 'B+', allergies: 'Penicillin', shareWithResponders: true },
        },
      );
      for (const account of [reporter, volunteer]) {
        await api(account.auth).post('/devices', {
          token: account === reporter ? TOKEN_A : TOKEN_B,
          platform: 'android',
        });
      }

      const created = await sos(reporter);
      const id = created.body.data.id;
      await api(volunteer.auth).post(`/volunteers/me/emergencies/${id}/accept`);
      await api(volunteer.auth).post(`/volunteers/me/emergencies/${id}/resolve`, {
        resolutionNote: 'Allergic reaction treated',
      });
      await settle();

      const sensitive = [
        'Asha',
        'Ravi',
        '90000',
        'Penicillin',
        'B+',
        'Allergic',
        String(CENTER.latitude),
        String(CENTER.longitude),
      ];
      const stored = await Notification.find();
      expect(stored.length).toBeGreaterThan(4);
      for (const n of stored) {
        const text = JSON.stringify({ title: n.title, body: n.body, data: n.data });
        for (const word of sensitive) expect(text).not.toContain(word);
        for (const key of n.data.keys())
          expect(notificationService.ALLOWED_DATA_KEYS).toContain(key);
      }

      expect(push.sent.length).toBeGreaterThan(0);
      for (const message of push.sent) {
        const text = JSON.stringify(message);
        for (const word of sensitive) expect(text).not.toContain(word);
        expect(Object.keys(message.data).sort()).toEqual(
          expect.arrayContaining(['notificationId', 'type']),
        );
        for (const key of Object.keys(message.data)) {
          expect([...notificationService.ALLOWED_DATA_KEYS, 'type', 'notificationId']).toContain(
            key,
          );
        }
      }
    });

    it('drops payload keys that are not on the allow-list', () => {
      expect(
        notificationService.sanitizeData({
          emergencyId: 'e1',
          phone: '+91 90000 00000',
          location: '20.0,73.7',
        }),
      ).toEqual({ emergencyId: 'e1' });
    });
  });

  describe('push delivery', () => {
    it('pushes to every registered device of the recipient and prunes dead tokens', async () => {
      push = fakePush({ invalid: [TOKEN_B] });
      setPushProvider(push.provider);
      const reporter = await createAccount();
      await api(reporter.auth).post('/devices', { token: TOKEN_A, platform: 'android' });
      await api(reporter.auth).post('/devices', { token: TOKEN_B, platform: 'ios' });

      await sos(reporter);

      const first = push.sent.find((m) => m.data.type === 'EMERGENCY_CREATED');
      expect(first.tokens.sort()).toEqual([TOKEN_A, TOKEN_B].sort());
      expect(first).toMatchObject({
        title: 'Alert sent',
        data: { emergencyId: expect.any(String) },
      });
      expect(await DeviceToken.exists({ token: TOKEN_B })).toBeNull();
      expect(await DeviceToken.exists({ token: TOKEN_A })).not.toBeNull();
    });

    it('a push failure never breaks the business flow', async () => {
      setPushProvider(fakePush({ fail: true }).provider);
      const reporter = await createAccount();
      await api(reporter.auth).post('/devices', { token: TOKEN_A, platform: 'android' });

      const res = await sos(reporter);

      expect(res.status).toBe(201);
      expect(
        await Notification.countDocuments({ recipientUserId: reporter.user._id }),
      ).toBeGreaterThan(0);
    });

    it('a storage failure never breaks the business flow either', async () => {
      const reporter = await createAccount();
      jest.spyOn(Notification, 'insertMany').mockRejectedValueOnce(new Error('db down'));

      const res = await sos(reporter);

      expect(res.status).toBe(201);
      jest.restoreAllMocks();
    });
  });

  describe('devices', () => {
    it('a token moves to the account that signed in last on that device', async () => {
      const first = await createAccount();
      const second = await createAccount({ role: 'VOLUNTEER' });

      await api(first.auth).post('/devices', { token: TOKEN_A, platform: 'android' });
      const res = await api(second.auth).post('/devices', { token: TOKEN_A, platform: 'android' });

      expect(res.status).toBe(201);
      const stored = await DeviceToken.find({ token: TOKEN_A });
      expect(stored).toHaveLength(1);
      expect(stored[0].userId.toString()).toBe(second.user.id);
    });

    it('only the owner can remove a token', async () => {
      const owner = await createAccount();
      const other = await createAccount();
      await api(owner.auth).post('/devices', { token: TOKEN_A, platform: 'android' });

      const denied = await api(other.auth).delete(`/devices/${TOKEN_A}`);
      const removed = await api(owner.auth).delete(`/devices/${TOKEN_A}`);

      expect(denied.body.data.removed).toBe(false);
      expect(removed.body.data.removed).toBe(true);
      expect(await DeviceToken.countDocuments()).toBe(0);
    });

    it('validates the token and platform', async () => {
      const account = await createAccount();

      const res = await api(account.auth).post('/devices', { token: 'x y', platform: 'symbian' });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('VALIDATION_ERROR');
    });
  });

  describe('notification center', () => {
    async function inboxWithTwo() {
      const reporter = await createAccount();
      await sos(reporter); // EMERGENCY_CREATED + EMERGENCY_UNASSIGNED
      return reporter;
    }

    it('counts unread, marks one read, then all', async () => {
      const reporter = await inboxWithTwo();
      const me = api(reporter.auth);

      expect((await me.get('/notifications/unread-count')).body.data.unreadCount).toBe(2);
      const list = await me.get('/notifications');
      const [latest] = list.body.data.items;

      const read = await me.patch(`/notifications/${latest.id}/read`);
      expect(read.body.data).toMatchObject({ id: latest.id, isRead: true });
      expect((await me.get('/notifications?unreadOnly=true')).body.data.total).toBe(1);

      await me.post('/notifications/read-all');
      expect((await me.get('/notifications')).body.data.unreadCount).toBe(0);
    });

    it('lists newest first with paging', async () => {
      const reporter = await inboxWithTwo();

      const res = await api(reporter.auth).get('/notifications?limit=1&page=2');

      expect(res.body.data).toMatchObject({ page: 2, limit: 1, total: 2, unreadCount: 2 });
      expect(res.body.data.items[0].type).toBe('EMERGENCY_CREATED');
    });

    it("another account's notification is not found", async () => {
      const reporter = await inboxWithTwo();
      const [n] = (await api(reporter.auth).get('/notifications')).body.data.items;
      const other = await createAccount();

      const res = await api(other.auth).patch(`/notifications/${n.id}/read`);

      expect(res.status).toBe(404);
      expect((await Notification.findById(n.id)).readAt).toBeNull();
    });

    it('requires authentication', async () => {
      const res = await request(app).get('/api/v1/notifications');

      expect(res.status).toBe(401);
    });
  });

  describe('admin notices', () => {
    it('reach every approved volunteer with an active account, and nobody else', async () => {
      const admin = await createAccount({ role: 'ADMIN' });
      const approved = await createVolunteer({ status: 'OFFLINE' });
      const hindi = await createVolunteer();
      await User.updateOne({ _id: hindi.user._id }, { preferredLanguage: 'hi' });
      const pending = await createVolunteer({ verificationStatus: 'PENDING' });
      const suspended = await createVolunteer({ accountStatus: 'SUSPENDED' });
      const user = await createAccount();

      const res = await api(admin.auth).post('/admin/notices', {
        message: 'Ghat 4 is closed; use the north entrance.',
      });
      await settle();

      expect(res.status).toBe(201);
      expect(res.body.data.recipients).toBe(2);
      const notice = await Notification.findOne({ recipientUserId: approved.user._id });
      expect(notice).toMatchObject({
        type: 'ADMIN_NOTICE',
        title: 'Notice from the control room',
        body: 'Ghat 4 is closed; use the north entrance.',
      });
      const translated = await Notification.findOne({ recipientUserId: hindi.user._id });
      expect(translated.title).toBe(TEMPLATES.ADMIN_NOTICE.VOLUNTEER.title.hi);
      for (const account of [pending, suspended, user]) {
        expect(await Notification.countDocuments({ recipientUserId: account.user._id })).toBe(0);
      }
    });

    it('only admins can send notices, and the message is required', async () => {
      const admin = await createAccount({ role: 'ADMIN' });
      const volunteer = await createVolunteer();

      const forbidden = await api(volunteer.auth).post('/admin/notices', { message: 'Hello all' });
      const empty = await api(admin.auth).post('/admin/notices', { message: ' ' });

      expect(forbidden.status).toBe(403);
      expect(empty.status).toBe(400);
    });
  });
});
