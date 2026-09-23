const request = require('supertest');
const { createApp } = require('../../src/app');
const { supportsTransactions } = require('../../src/config/database');
const { Emergency, EmergencyAssignment, User } = require('../../src/models');
const { useTestDatabase } = require('../helpers/db');

describe('API foundation', () => {
  useTestDatabase();
  const app = createApp();

  it('reports health with the standard success envelope', async () => {
    const res = await request(app).get('/api/v1/health');

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      success: true,
      message: 'OK',
      data: { status: 'ok', database: 'connected' },
    });
  });

  it('returns the standard error envelope for unknown routes', async () => {
    const res = await request(app).get('/api/v1/does-not-exist');

    expect(res.status).toBe(404);
    expect(res.body).toEqual({
      success: false,
      message: expect.any(String),
      code: 'NOT_FOUND',
      errors: [],
    });
  });

  it('rejects malformed JSON with VALIDATION_ERROR', async () => {
    const res = await request(app)
      .post('/api/v1/health')
      .set('Content-Type', 'application/json')
      .send('{"broken":');

    expect(res.status).toBe(400);
    expect(res.body.code).toBe('VALIDATION_ERROR');
  });

  it('sets security headers and hides the framework', async () => {
    const res = await request(app).get('/api/v1/health');

    expect(res.headers['x-powered-by']).toBeUndefined();
    expect(res.headers['x-content-type-options']).toBe('nosniff');
  });

  it('runs on a deployment that supports transactions', () => {
    expect(supportsTransactions()).toBe(true);
  });

  it('never serializes password hashes', async () => {
    const user = await User.create({
      name: 'Test',
      email: 't@example.com',
      username: 'tester',
      passwordHash: 'hash',
    });
    const json = user.toJSON();

    expect(json.passwordHash).toBeUndefined();
    expect(json.id).toBe(user._id.toString());
  });

  it('enforces one open emergency per user at the database level', async () => {
    const user = await User.create({
      name: 'U',
      email: 'u@example.com',
      username: 'user1',
      passwordHash: 'hash',
    });
    await Emergency.create({ alertNumber: 'A-1', userId: user._id });

    await expect(Emergency.create({ alertNumber: 'A-2', userId: user._id })).rejects.toMatchObject({
      code: 11000,
    });
    await expect(
      Emergency.create({ alertNumber: 'A-3', userId: user._id, isOpen: false, status: 'RESOLVED' }),
    ).resolves.toBeDefined();
  });

  it('enforces one active assignment per volunteer at the database level', async () => {
    const base = {
      volunteerId: '64b000000000000000000001',
      attemptNumber: 1,
      dispatchedAt: new Date(),
      expiresAt: new Date(Date.now() + 120000),
    };
    await EmergencyAssignment.create({ ...base, emergencyId: '64b0000000000000000000a1' });

    await expect(
      EmergencyAssignment.create({ ...base, emergencyId: '64b0000000000000000000a2' }),
    ).rejects.toMatchObject({ code: 11000 });
  });
});
