const request = require('supertest');
const { createApp } = require('../../src/app');
const { Hospital, MedicalCamp, User, Volunteer } = require('../../src/models');
const { seedDemoData, DEMO_PASSWORD, CENTER } = require('../../scripts/seed-demo');
const { useTestDatabase } = require('../helpers/db');

/** The demo must be repeatable: the script runs before every presentation. */
describe('Demo seed', () => {
  useTestDatabase();
  const app = createApp();

  it('creates clearly labelled demo data that a demo can run on', async () => {
    await seedDemoData();

    // No invented hospitals: real ones come from OpenStreetMap (doc 18).
    expect(await Hospital.countDocuments()).toBe(0);
    expect(await Volunteer.countDocuments()).toBe(4);
    for (const name of (await MedicalCamp.find()).map((c) => c.name)) {
      expect(name).toMatch(/Demo/);
    }

    // Two volunteers on duty near the ghat, one off duty, one awaiting review.
    const volunteers = await Volunteer.find().populate('userId', 'name');
    expect(volunteers.filter((v) => v.status === 'ACTIVE')).toHaveLength(2);
    expect(volunteers.filter((v) => v.verificationStatus === 'PENDING')).toHaveLength(1);
    for (const volunteer of volunteers.filter((v) => v.status === 'ACTIVE')) {
      expect(volunteer.currentLocation.coordinates).toHaveLength(2);
      expect(volunteer.locationUpdatedAt).toBeInstanceOf(Date);
    }
  });

  it('shows the user only the camp that is valid right now', async () => {
    await seedDemoData();
    const login = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'demo_asha', password: DEMO_PASSWORD });

    const res = await request(app)
      .get(`/api/v1/facilities/nearby?latitude=${CENTER.latitude}&longitude=${CENTER.longitude}`)
      .set('Authorization', `Bearer ${login.body.data.accessToken}`);

    expect(login.status).toBe(200);
    const camps = res.body.data.filter((f) => f.type === 'CAMP');
    expect(camps.map((c) => c.name)).toEqual(['Demo Ramkund Relief Camp']);
    expect(await MedicalCamp.countDocuments()).toBe(3);
  });

  it('can be run again without duplicating anything', async () => {
    await seedDemoData();
    const first = await User.countDocuments();

    await seedDemoData();

    expect(await User.countDocuments()).toBe(first);
    expect(await Hospital.countDocuments()).toBe(0);
    expect(await MedicalCamp.countDocuments()).toBe(3);
    expect(await Volunteer.countDocuments()).toBe(4);
  });

  it('lets every demo account sign in', async () => {
    await seedDemoData();

    const logins = await Promise.all(
      ['demo_asha', 'demo_ravi', 'demo_sana', 'demo_imran', 'demo_priya'].map((identifier) =>
        request(app).post('/api/v1/auth/login').send({ identifier, password: DEMO_PASSWORD }),
      ),
    );

    expect(logins.map((r) => r.status)).toEqual([200, 200, 200, 200, 200]);
    expect(logins.map((r) => r.body.data.user.role)).toEqual([
      'USER',
      'VOLUNTEER',
      'VOLUNTEER',
      'VOLUNTEER',
      'VOLUNTEER',
    ]);
  });
});
