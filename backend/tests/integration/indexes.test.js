const models = require('../../src/models');
const { useTestDatabase } = require('../helpers/db');

/**
 * The indexes the system depends on: geo search for dispatch and nearby
 * facilities, the race guards from D-022, and expiry of refresh tokens.
 * A missing one would only show up as a slow or wrong system in production.
 */
const REQUIRED = {
  User: [
    { key: { email: 1 }, unique: true },
    { key: { username: 1 }, unique: true },
    { key: { role: 1, createdAt: -1 } },
  ],
  Volunteer: [
    { key: { userId: 1 }, unique: true },
    { key: { currentLocation: '2dsphere' } },
    { key: { verificationStatus: 1, status: 1 } },
  ],
  Emergency: [
    { key: { location: '2dsphere' } },
    { key: { userId: 1, createdAt: -1 } },
    { key: { status: 1, createdAt: -1 } },
    // One open emergency per user (D-022).
    { key: { userId: 1 }, unique: true, partial: true },
  ],
  EmergencyAssignment: [
    { key: { status: 1, expiresAt: 1 } },
    // One active assignment per emergency, and per volunteer (D-022).
    { key: { emergencyId: 1 }, unique: true, partial: true },
    { key: { volunteerId: 1 }, unique: true, partial: true },
  ],
  Hospital: [{ key: { location: '2dsphere' } }],
  MedicalCamp: [
    { key: { location: '2dsphere' } },
    { key: { isActive: 1, isDeleted: 1, startDateTime: 1, endDateTime: 1 } },
  ],
  Notification: [{ key: { recipientUserId: 1, createdAt: -1 } }],
  DeviceToken: [{ key: { token: 1 }, unique: true }],
  RefreshToken: [{ key: { expiresAt: 1 }, ttl: true }],
};

const sameKey = (a, b) =>
  Object.keys(a).length === Object.keys(b).length &&
  Object.entries(a).every(([field, order]) => `${b[field]}` === `${order}`);

describe('Database indexes', () => {
  useTestDatabase();

  it.each(Object.entries(REQUIRED))('%s has the indexes it relies on', async (name, expected) => {
    const model = models[name];
    await model.createIndexes();
    const actual = await model.collection.indexes();

    for (const wanted of expected) {
      const match = actual.find(
        (index) =>
          sameKey(wanted.key, index.key) &&
          Boolean(index.unique) === Boolean(wanted.unique) &&
          Boolean(index.partialFilterExpression) === Boolean(wanted.partial) &&
          (wanted.ttl ? index.expireAfterSeconds === 0 : index.expireAfterSeconds === undefined),
      );
      expect(match ?? { missing: wanted, actual }).toMatchObject({ key: expect.any(Object) });
    }
  });
});
