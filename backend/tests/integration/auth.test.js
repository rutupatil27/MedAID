const request = require('supertest');
const jwt = require('jsonwebtoken');
const { createApp } = require('../../src/app');
const { RefreshToken } = require('../../src/models');
const { useTestDatabase } = require('../helpers/db');
const { createAccount, registerViaApi } = require('../helpers/factories');

describe('Authentication', () => {
  useTestDatabase();
  const app = createApp();

  describe('POST /auth/register', () => {
    it('creates a USER account and returns a session without the password hash', async () => {
      const res = await registerViaApi(app, { email: 'Asha@Example.com', username: 'asha_p' });

      expect(res.status).toBe(201);
      expect(res.body.data.user).toMatchObject({
        email: 'asha@example.com',
        username: 'asha_p',
        role: 'USER',
        accountStatus: 'ACTIVE',
      });
      expect(res.body.data.user.passwordHash).toBeUndefined();
      expect(res.body.data.accessToken).toEqual(expect.any(String));
      expect(res.body.data.refreshToken).toEqual(expect.any(String));
    });

    it('ignores attempts to self-register with an elevated role', async () => {
      const res = await registerViaApi(app, { role: 'ADMIN' });

      expect(res.status).toBe(201);
      expect(res.body.data.user.role).toBe('USER');
    });

    it('rejects duplicate email or username with CONFLICT', async () => {
      await registerViaApi(app, { email: 'dup@example.com', username: 'dupuser' });
      const res = await registerViaApi(app, { email: 'dup@example.com', username: 'dupuser' });

      expect(res.status).toBe(409);
      expect(res.body.code).toBe('CONFLICT');
      expect(res.body.errors.map((e) => e.field).sort()).toEqual(['body.email', 'body.username']);
    });

    it('validates input with field-level errors', async () => {
      const res = await registerViaApi(app, { email: 'not-an-email', password: 'short' });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('VALIDATION_ERROR');
      const fields = res.body.errors.map((e) => e.field);
      expect(fields).toEqual(expect.arrayContaining(['body.email', 'body.password']));
    });
  });

  describe('POST /auth/login', () => {
    it('logs in with email or username', async () => {
      const { user, password } = await createAccount({
        username: 'ravi',
        email: 'ravi@example.com',
      });

      const byEmail = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: 'RAVI@example.com', password });
      const byUsername = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: 'ravi', password });

      expect(byEmail.status).toBe(200);
      expect(byUsername.status).toBe(200);
      expect(byUsername.body.data.user.id).toBe(user.id);
    });

    it('returns AUTH_INVALID for a wrong password or unknown account', async () => {
      await createAccount({ username: 'meera' });

      const wrong = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: 'meera', password: 'nope12345' });
      const unknown = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: 'ghost', password: 'nope12345' });

      expect(wrong.status).toBe(401);
      expect(wrong.body.code).toBe('AUTH_INVALID');
      expect(unknown.body.code).toBe('AUTH_INVALID');
    });

    it('blocks suspended accounts', async () => {
      const { password } = await createAccount({ username: 'blocked', accountStatus: 'SUSPENDED' });

      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: 'blocked', password });

      expect(res.status).toBe(403);
      expect(res.body.code).toBe('ACCOUNT_SUSPENDED');
    });
  });

  describe('token lifecycle', () => {
    it('rejects missing, malformed and expired access tokens', async () => {
      const { user } = await createAccount();
      const expired = jwt.sign({ role: 'USER' }, process.env.JWT_ACCESS_SECRET, {
        subject: user.id,
        issuer: 'medaid-api',
        audience: 'medaid-app',
        expiresIn: -10,
      });

      for (const header of [undefined, 'Bearer garbage', `Bearer ${expired}`]) {
        const req = request(app).get('/api/v1/users/me');
        if (header) req.set('Authorization', header);
        const res = await req;
        expect(res.status).toBe(401);
        expect(res.body.code).toBe('AUTH_UNAUTHORIZED');
      }
    });

    it('rotates refresh tokens and detects reuse', async () => {
      const { refreshToken } = await createAccount();

      const first = await request(app).post('/api/v1/auth/refresh').send({ refreshToken });
      expect(first.status).toBe(200);
      const rotated = first.body.data.refreshToken;
      expect(rotated).not.toBe(refreshToken);

      // Simulate the grace window having passed, then reuse the old token.
      await RefreshToken.updateOne(
        { replacedByHash: { $ne: null } },
        { $set: { revokedAt: new Date(Date.now() - 60000) } },
      );
      // The successor is valid until the reuse is detected.
      expect(await RefreshToken.countDocuments({ revokedAt: null })).toBe(1);
      const reuse = await request(app).post('/api/v1/auth/refresh').send({ refreshToken });
      expect(reuse.status).toBe(401);

      const afterReuse = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: rotated });
      expect(afterReuse.status).toBe(401);
    });

    it('allows a retry within the grace window when the rotation response was lost', async () => {
      const { refreshToken } = await createAccount();

      const first = await request(app).post('/api/v1/auth/refresh').send({ refreshToken });
      const retry = await request(app).post('/api/v1/auth/refresh').send({ refreshToken });

      expect(first.status).toBe(200);
      expect(retry.status).toBe(200);
      const lostSuccessor = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: first.body.data.refreshToken });
      expect(lostSuccessor.status).toBe(401);
    });

    it('logout revokes the refresh token family', async () => {
      const { refreshToken } = await createAccount();

      const logout = await request(app).post('/api/v1/auth/logout').send({ refreshToken });
      const refresh = await request(app).post('/api/v1/auth/refresh').send({ refreshToken });

      expect(logout.status).toBe(200);
      expect(refresh.status).toBe(401);
    });

    it('suspension takes effect immediately for existing access tokens', async () => {
      const { user, auth } = await createAccount();
      await user.updateOne({ accountStatus: 'SUSPENDED' });

      const res = await request(app).get('/api/v1/users/me').set('Authorization', auth);

      expect(res.status).toBe(403);
      expect(res.body.code).toBe('ACCOUNT_SUSPENDED');
    });
  });

  describe('POST /auth/change-password', () => {
    it('changes the password, clears the forced-change flag and ends other sessions', async () => {
      const { auth, refreshToken, password } = await createAccount({ mustChangePassword: true });

      const res = await request(app)
        .post('/api/v1/auth/change-password')
        .set('Authorization', auth)
        .send({ currentPassword: password, newPassword: 'BrandNew99' });

      expect(res.status).toBe(200);
      expect(res.body.data.user.mustChangePassword).toBe(false);

      const oldRefresh = await request(app).post('/api/v1/auth/refresh').send({ refreshToken });
      expect(oldRefresh.status).toBe(401);

      const newSession = await request(app)
        .get('/api/v1/users/me')
        .set('Authorization', `Bearer ${res.body.data.accessToken}`);
      expect(newSession.status).toBe(200);
    });

    it('rejects an incorrect current password', async () => {
      const { auth } = await createAccount();

      const res = await request(app)
        .post('/api/v1/auth/change-password')
        .set('Authorization', auth)
        .send({ currentPassword: 'wrongpass1', newPassword: 'BrandNew99' });

      expect(res.status).toBe(401);
      expect(res.body.code).toBe('AUTH_INVALID');
    });
  });

  describe('/users/me', () => {
    it('returns and updates the current profile', async () => {
      const { auth } = await createAccount();

      const update = await request(app)
        .patch('/api/v1/users/me')
        .set('Authorization', auth)
        .send({
          preferredLanguage: 'mr',
          medicalProfile: { bloodGroup: 'O+', shareWithResponders: true },
        });
      const me = await request(app).get('/api/v1/users/me').set('Authorization', auth);

      expect(update.status).toBe(200);
      expect(me.body.data).toMatchObject({
        preferredLanguage: 'mr',
        medicalProfile: { bloodGroup: 'O+', shareWithResponders: true },
      });
      expect(me.body.data.passwordHash).toBeUndefined();
    });

    it('does not let staff accounts set a medical profile', async () => {
      const { auth } = await createAccount({ role: 'VOLUNTEER' });

      const res = await request(app)
        .patch('/api/v1/users/me')
        .set('Authorization', auth)
        .send({ medicalProfile: { bloodGroup: 'A+' } });

      expect(res.status).toBe(400);
    });
  });
});
