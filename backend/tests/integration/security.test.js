const jwt = require('jsonwebtoken');
const request = require('supertest');
const express = require('express');
const { createApp } = require('../../src/app');
const env = require('../../src/config/env');
const pino = require('pino');
const { REDACT } = require('../../src/utils/logRedaction');
const { Emergency, User, Volunteer, Notification } = require('../../src/models');
const { createRateLimiter } = require('../../src/middleware/rateLimiter');
const { setDocumentStorage } = require('../../src/integrations/cloudinary/documentStorage');
const { useTestDatabase } = require('../helpers/db');
const { createAccount } = require('../helpers/factories');
const { CENTER, createVolunteer, createOpenEmergency, dispatch } = require('../helpers/scenario');

const SIGN_OPTIONS = { algorithm: 'HS256', issuer: 'medaid-api', audience: 'medaid-app' };
const PDF = Buffer.from('%PDF-1.7\nMedAID test document\n');

describe('Security (doc 22, doc 24)', () => {
  useTestDatabase();
  const app = createApp();

  const bearer = (payload, options = {}) =>
    `Bearer ${jwt.sign(payload, env.auth.accessSecret, { ...SIGN_OPTIONS, ...options })}`;

  const me = (auth) => request(app).get('/api/v1/users/me').set('Authorization', auth);

  describe('tokens', () => {
    it('rejects an expired access token', async () => {
      const { user } = await createAccount();

      const res = await me(bearer({ role: user.role }, { subject: user.id, expiresIn: '-1m' }));

      expect(res.status).toBe(401);
      expect(res.body.code).toBe('AUTH_UNAUTHORIZED');
    });

    it('rejects a tampered signature', async () => {
      const account = await createAccount();
      const [header, payload] = account.accessToken.split('.');

      const res = await me(`Bearer ${header}.${payload}.forged-signature`);

      expect(res.status).toBe(401);
    });

    it('rejects a token signed with another secret', async () => {
      const { user } = await createAccount();
      const forged = jwt.sign({ role: 'ADMIN' }, 'not-the-real-secret-but-long-enough-000000', {
        ...SIGN_OPTIONS,
        subject: user.id,
        expiresIn: '1h',
      });

      const res = await me(`Bearer ${forged}`);

      expect(res.status).toBe(401);
    });

    it.each([
      ['issuer', { issuer: 'someone-else' }],
      ['audience', { audience: 'another-app' }],
      ['algorithm', { algorithm: 'HS512' }],
    ])('rejects a token with the wrong %s', async (_label, options) => {
      const { user } = await createAccount();

      const res = await me(
        bearer({ role: user.role }, { subject: user.id, expiresIn: '1h', ...options }),
      );

      expect(res.status).toBe(401);
    });

    it('ignores the role inside the token and uses the stored one', async () => {
      const { user } = await createAccount({ role: 'USER' });

      const res = await request(app)
        .get('/api/v1/admin/dashboard')
        .set('Authorization', bearer({ role: 'ADMIN' }, { subject: user.id, expiresIn: '1h' }));

      expect(res.status).toBe(403);
    });

    it('rejects a token whose account no longer exists', async () => {
      const account = await createAccount();
      await User.deleteOne({ _id: account.user._id });

      const res = await me(account.auth);

      expect(res.status).toBe(401);
    });

    it('stops accepting tokens issued before a password change', async () => {
      const account = await createAccount();
      const older = bearer(
        { role: account.user.role, iat: Math.floor(Date.now() / 1000) - 600 },
        { subject: account.user.id, expiresIn: '1h' },
      );

      const changed = await request(app)
        .post('/api/v1/auth/change-password')
        .set('Authorization', account.auth)
        .send({ currentPassword: account.password, newPassword: 'BrandNew123' });

      expect(changed.status).toBe(200);
      expect((await me(older)).status).toBe(401);
      // The tokens handed out by the change itself keep working.
      expect((await me(`Bearer ${changed.body.data.accessToken}`)).status).toBe(200);
    });

    it.each([
      ['no scheme', 'abc.def.ghi'],
      ['empty bearer', 'Bearer '],
      ['wrong scheme', 'Basic dXNlcjpwYXNz'],
    ])('rejects a malformed Authorization header (%s)', async (_label, value) => {
      const res = await me(value);

      expect(res.status).toBe(401);
    });
  });

  describe('input validation', () => {
    it('does not let an operator object stand in for credentials', async () => {
      await createAccount({ email: 'asha@example.com', password: 'Secret123' });

      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: { $ne: null }, password: { $ne: null } });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('VALIDATION_ERROR');
    });

    it('ignores fields the client may not set', async () => {
      const account = await createAccount();

      const res = await request(app)
        .patch('/api/v1/users/me')
        .set('Authorization', account.auth)
        .send({
          name: 'Asha',
          role: 'ADMIN',
          accountStatus: 'SUSPENDED',
          mustChangePassword: true,
        });

      expect(res.status).toBe(200);
      expect(await User.findById(account.user._id)).toMatchObject({
        name: 'Asha',
        role: 'USER',
        accountStatus: 'ACTIVE',
        mustChangePassword: false,
      });
    });

    it('rejects an invalid id instead of querying with it', async () => {
      const account = await createAccount();

      const res = await request(app)
        .get('/api/v1/emergencies/not-an-id')
        .set('Authorization', account.auth);

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('VALIDATION_ERROR');
    });

    it('caps coordinates and paging', async () => {
      const account = await createAccount();

      const [coords, paging] = await Promise.all([
        request(app)
          .get('/api/v1/facilities/nearby?latitude=999&longitude=73.79')
          .set('Authorization', account.auth),
        request(app).get('/api/v1/emergencies/my?limit=10000').set('Authorization', account.auth),
      ]);

      expect(coords.status).toBe(400);
      expect(paging.status).toBe(400);
    });

    it('refuses an oversized JSON body', async () => {
      const account = await createAccount();

      const res = await request(app)
        .patch('/api/v1/users/me')
        .set('Authorization', account.auth)
        .send({ name: 'x'.repeat(200 * 1024) });

      expect(res.status).toBe(413);
    });
  });

  describe('uploads (doc 20)', () => {
    let volunteer;

    beforeEach(async () => {
      setDocumentStorage({
        upload: async () => ({
          publicId: 'medaid/test',
          resourceType: 'image',
          deliveryType: 'authenticated',
        }),
        destroy: async () => {},
        signedUrl: () => 'https://example.test/signed',
      });
      volunteer = await createVolunteer({ verificationStatus: 'NOT_SUBMITTED' });
    });

    const upload = (file, { name = 'id.pdf', type = 'ID_PROOF' } = {}) =>
      request(app)
        .post('/api/v1/volunteers/me/documents')
        .set('Authorization', volunteer.auth)
        .field('documentType', type)
        .attach('file', file, name);

    it('judges the file by its content, not its name', async () => {
      const res = await upload(Buffer.from('MZ\x90\x00 this is an executable'), { name: 'id.pdf' });

      expect(res.status).toBe(422);
      expect(res.body.code).toBe('FILE_UPLOAD_FAILED');
    });

    it('rejects an HTML payload disguised as an image', async () => {
      const res = await upload(Buffer.from('<script>alert(1)</script>'), { name: 'photo.png' });

      expect(res.status).toBe(422);
    });

    it('rejects a file over the size limit', async () => {
      const big = Buffer.concat([PDF, Buffer.alloc(env.uploads.maxBytes + 1024, 0x20)]);

      const res = await upload(big);

      expect(res.status).toBe(413);
    });

    it('rejects an unknown document type', async () => {
      const res = await upload(PDF, { type: 'PASSPORT_SCAN' });

      expect(res.status).toBe(400);
    });

    it('accepts a genuine PDF', async () => {
      const res = await upload(PDF);

      expect(res.status).toBe(201);
    });

    it('never returns storage identifiers to the volunteer', async () => {
      await upload(PDF);

      const res = await request(app)
        .get('/api/v1/volunteers/me/verification')
        .set('Authorization', volunteer.auth);

      const body = JSON.stringify(res.body);
      expect(body).not.toContain('publicId');
      expect(body).not.toContain('medaid/test');
    });
  });

  describe('data belonging to someone else', () => {
    it("a user cannot read another user's emergency", async () => {
      const { emergency } = await createOpenEmergency();
      const other = await createAccount();

      const res = await request(app)
        .get(`/api/v1/emergencies/${emergency.id}`)
        .set('Authorization', other.auth);

      expect(res.status).toBe(404);
    });

    it("a user cannot cancel another user's emergency", async () => {
      const { emergency } = await createOpenEmergency();
      const other = await createAccount();

      const res = await request(app)
        .post(`/api/v1/emergencies/${emergency.id}/cancel`)
        .set('Authorization', other.auth)
        .send({});

      expect(res.status).toBe(404);
      expect((await Emergency.findById(emergency._id)).status).toBe('CREATED');
    });

    it("a volunteer cannot take another volunteer's assignment", async () => {
      const responder = await createVolunteer();
      const bystander = await createVolunteer();
      const { emergency } = await createOpenEmergency();
      await dispatch(emergency, responder.volunteer);

      const [detail, accept] = await Promise.all([
        request(app)
          .get(`/api/v1/volunteers/me/emergencies/${emergency.id}`)
          .set('Authorization', bystander.auth),
        request(app)
          .post(`/api/v1/volunteers/me/emergencies/${emergency.id}/accept`)
          .set('Authorization', bystander.auth),
      ]);

      expect(detail.status).toBe(404);
      expect(accept.status).toBe(404);
      expect(await Volunteer.findById(bystander.volunteer._id)).toMatchObject({ status: 'ACTIVE' });
    });

    it("a user cannot read another account's notifications", async () => {
      const owner = await createAccount();
      const [notification] = await Notification.insertMany([
        {
          recipientUserId: owner.user._id,
          type: 'EMERGENCY_CREATED',
          title: 'Alert sent',
          body: 'x',
        },
      ]);
      const other = await createAccount();

      const [list, read] = await Promise.all([
        request(app).get('/api/v1/notifications').set('Authorization', other.auth),
        request(app)
          .patch(`/api/v1/notifications/${notification.id}/read`)
          .set('Authorization', other.auth),
      ]);

      expect(list.body.data.items).toEqual([]);
      expect(read.status).toBe(404);
    });

    it('volunteer locations are admin-only', async () => {
      await createVolunteer({ location: CENTER });
      const user = await createAccount();

      const res = await request(app)
        .get('/api/v1/admin/volunteers/locations')
        .set('Authorization', user.auth);

      expect(res.status).toBe(403);
    });
  });

  describe('transport and logging', () => {
    it('sets security headers and hides the framework', async () => {
      const res = await request(app).get('/api/v1/health');

      expect(res.headers['x-powered-by']).toBeUndefined();
      expect(res.headers['x-content-type-options']).toBe('nosniff');
      expect(res.headers['x-frame-options']).toBe('SAMEORIGIN');
    });

    it('allows only configured browser origins', async () => {
      const allowed = env.corsOrigins[0];

      const [ok, blocked] = await Promise.all([
        request(app).get('/api/v1/health').set('Origin', allowed),
        request(app).get('/api/v1/health').set('Origin', 'https://evil.example'),
      ]);

      expect(ok.headers['access-control-allow-origin']).toBe(allowed);
      expect(blocked.headers['access-control-allow-origin']).toBeUndefined();
    });

    it('rate limits and answers with a language-neutral code', async () => {
      const limited = express();
      limited.use(createRateLimiter({ windowMs: 60_000, limit: 2 }));
      limited.get('/probe', (_req, res) => res.json({ ok: true }));

      const statuses = [];
      for (let i = 0; i < 4; i += 1) {
        const res = await request(limited).get('/probe');
        statuses.push(res.status);
        if (res.status === 429) expect(res.body.code).toBe('RATE_LIMITED');
      }

      expect(statuses).toEqual([200, 200, 429, 429]);
    });

    it('redacts credentials and tokens from logs', () => {
      const lines = [];
      const probe = pino({ redact: REDACT }, { write: (line) => lines.push(line) });

      probe.info(
        {
          req: { headers: { authorization: 'Bearer super-secret-token' } },
          body: { password: 'Secret123', refreshToken: 'refresh-secret', fcmToken: 'device-abc' },
        },
        'login attempt',
      );

      const output = lines.join('');
      for (const secret of ['Secret123', 'super-secret-token', 'refresh-secret', 'device-abc']) {
        expect(output).not.toContain(secret);
      }
      expect(output).toContain(REDACT.censor);
      expect(output).toContain('login attempt');
    });

    it('never leaks internals in an error response', async () => {
      const res = await request(app).get('/api/v1/not-a-route');

      expect(res.status).toBe(404);
      expect(res.body).toMatchObject({ success: false, code: 'NOT_FOUND' });
      expect(JSON.stringify(res.body)).not.toMatch(/at .*\.js:\d+|node_modules/);
    });
  });
});
