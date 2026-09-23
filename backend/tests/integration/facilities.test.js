const request = require('supertest');
const { createApp } = require('../../src/app');
const { Hospital, MedicalCamp } = require('../../src/models');
const { useTestDatabase } = require('../helpers/db');
const { createAccount } = require('../helpers/factories');

const HOUR = 60 * 60 * 1000;
// Around Ramkund, Nashik.
const here = { latitude: 20.0086, longitude: 73.7925 };
const point = (latitude, longitude) => ({ type: 'Point', coordinates: [longitude, latitude] });

async function seed() {
  const now = Date.now();
  await Hospital.create([
    { name: 'Near Hospital', location: point(20.0101, 73.793), services: ['Emergency'] },
    { name: 'Far Hospital', location: point(20.2, 73.9) },
    { name: 'Closed Hospital', location: point(20.0087, 73.7926), isActive: false },
  ]);
  const camp = (name, overrides) => ({
    name,
    address: 'Ghat road',
    location: point(20.009, 73.7928),
    startDateTime: new Date(now - HOUR),
    endDateTime: new Date(now + HOUR),
    ...overrides,
  });
  await MedicalCamp.create([
    camp('Open Camp', {}),
    camp('Expired Camp', {
      startDateTime: new Date(now - 3 * HOUR),
      endDateTime: new Date(now - HOUR),
    }),
    camp('Future Camp', {
      startDateTime: new Date(now + HOUR),
      endDateTime: new Date(now + 2 * HOUR),
    }),
    camp('Deactivated Camp', { isActive: false }),
    camp('Deleted Camp', { isDeleted: true }),
  ]);
}

describe('Nearby facilities', () => {
  useTestDatabase();
  const app = createApp();

  it('merges hospitals and only currently valid camps, nearest first', async () => {
    await seed();
    const { auth } = await createAccount();

    const res = await request(app)
      .get('/api/v1/facilities/nearby')
      .query({ ...here, radiusMeters: 5000 })
      .set('Authorization', auth);

    expect(res.status).toBe(200);
    const names = res.body.data.map((f) => f.name);
    expect(names).toEqual(['Open Camp', 'Near Hospital']);
    expect(res.body.data[0]).toMatchObject({
      type: 'CAMP',
      location: { latitude: 20.009, longitude: 73.7928 },
      distanceMeters: expect.any(Number),
    });
  });

  it('filters by type and exposes single-type endpoints', async () => {
    await seed();
    const { auth } = await createAccount();

    const camps = await request(app)
      .get('/api/v1/facilities/nearby')
      .query({ ...here, type: 'CAMP' })
      .set('Authorization', auth);
    const hospitals = await request(app)
      .get('/api/v1/hospitals/nearby')
      .query({ ...here, radiusMeters: 50000 })
      .set('Authorization', auth);

    expect(camps.body.data.map((f) => f.name)).toEqual(['Open Camp']);
    expect(hospitals.body.data.map((f) => f.name)).toEqual(['Near Hospital', 'Far Hospital']);
  });

  it('hides camp details outside the validity window (D-012)', async () => {
    await seed();
    const { auth } = await createAccount();
    const open = await MedicalCamp.findOne({ name: 'Open Camp' });
    const expired = await MedicalCamp.findOne({ name: 'Expired Camp' });

    const ok = await request(app)
      .get(`/api/v1/medical-camps/${open.id}`)
      .set('Authorization', auth);
    const gone = await request(app)
      .get(`/api/v1/medical-camps/${expired.id}`)
      .set('Authorization', auth);

    expect(ok.status).toBe(200);
    expect(gone.status).toBe(404);
  });

  it('requires valid coordinates', async () => {
    const { auth } = await createAccount();

    const res = await request(app)
      .get('/api/v1/facilities/nearby')
      .query({ latitude: 200, longitude: 73 })
      .set('Authorization', auth);

    expect(res.status).toBe(400);
  });
});
