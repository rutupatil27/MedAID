/**
 * Demo data for a presentation or a fresh environment:
 * hospitals, camps in each lifecycle state, volunteers and one user, all
 * around Ramkund in Nashik.
 *
 *   npm run seed:demo
 *
 * Everything is clearly labelled "Demo" and is safe to run repeatedly: records
 * are matched by name or email and updated in place. It refuses to touch a
 * production database unless SEED_DEMO_FORCE=true.
 */
const env = require('../src/config/env');
const logger = require('../src/utils/logger');
const { Hospital, MedicalCamp, User, Volunteer } = require('../src/models');
const { connectDatabase, disconnectDatabase } = require('../src/config/database');
const { hashPassword } = require('../src/services/auth/password.service');
const { ROLES, VERIFICATION_STATUS, VOLUNTEER_STATUS } = require('../src/config/constants');

/**
 * Where the demo data is placed. Defaults to Ramkund in Nashik; set
 * SEED_DEMO_LAT and SEED_DEMO_LNG to put it around you instead, which is what
 * you want when demonstrating on a real phone somewhere else.
 */
const CENTER = Object.freeze({
  latitude: Number(process.env.SEED_DEMO_LAT ?? 20.0086),
  longitude: Number(process.env.SEED_DEMO_LNG ?? 73.7925),
});

if (!Number.isFinite(CENTER.latitude) || !Number.isFinite(CENTER.longitude)) {
  throw new Error('SEED_DEMO_LAT and SEED_DEMO_LNG must be numbers');
}
const DEMO_PASSWORD = process.env.SEED_DEMO_PASSWORD || 'DemoPass123';

/** Invented hospitals are off by default: real ones come from OpenStreetMap. */
const SEED_HOSPITALS = process.env.SEED_DEMO_HOSPITALS === 'true';

const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

const point = ({ latitude, longitude }) => ({ type: 'Point', coordinates: [longitude, latitude] });

/** Moves a point roughly `meters` north and east. */
const near = (north = 0, east = 0) => ({
  latitude: CENTER.latitude + north / 111_320,
  longitude: CENTER.longitude + east / (111_320 * Math.cos((CENTER.latitude * Math.PI) / 180)),
});

const HOSPITALS = [
  {
    name: 'Demo Civil Hospital, Panchavati',
    location: near(700, -400),
    address: 'Panchavati, Nashik (demo data)',
    contact: { phone: '+91 253 000 0001' },
    services: ['Emergency', 'Trauma', 'Ambulance'],
    hasEmergencyDepartment: true,
  },
  {
    name: 'Demo Ghat Aid Post',
    location: near(-250, 150),
    address: 'Near Ramkund, Nashik (demo data)',
    contact: { phone: '+91 253 000 0002' },
    services: ['First aid', 'Oral rehydration'],
    hasEmergencyDepartment: false,
  },
  {
    name: 'Demo Trimbak Road Hospital',
    location: near(-1600, -2600),
    address: 'Trimbak Road, Nashik (demo data)',
    contact: { phone: '+91 253 000 0003' },
    services: ['Emergency', 'Cardiology'],
    hasEmergencyDepartment: true,
  },
  {
    name: 'Demo Nashik Road Medical Centre',
    location: near(-6000, 5000),
    address: 'Nashik Road (demo data)',
    contact: { phone: '+91 253 000 0004' },
    services: ['Emergency'],
    hasEmergencyDepartment: true,
  },
];

const camps = (now) => [
  {
    name: 'Demo Ramkund Relief Camp',
    description: 'Open now: first aid, drinking water and heat-stroke care.',
    location: near(120, 90),
    address: 'Ramkund ghat, Nashik (demo data)',
    services: ['First aid', 'Drinking water', 'Heat stroke'],
    contact: { name: 'Demo camp lead', phone: '+91 253 000 0010' },
    startDateTime: new Date(now - 2 * HOUR),
    endDateTime: new Date(now + 10 * HOUR),
  },
  {
    name: 'Demo Tapovan Camp',
    description: 'Opens in two days: vaccination and general check-up.',
    location: near(1500, 1200),
    address: 'Tapovan, Nashik (demo data)',
    services: ['Check-up', 'Vaccination'],
    contact: { name: 'Demo camp lead', phone: '+91 253 000 0011' },
    startDateTime: new Date(now + 2 * DAY),
    endDateTime: new Date(now + 3 * DAY),
  },
  {
    name: 'Demo Kalaram Camp (finished)',
    description: 'Closed yesterday: kept to show that users only see valid camps.',
    location: near(-500, 600),
    address: 'Kalaram temple area, Nashik (demo data)',
    services: ['First aid'],
    contact: { name: 'Demo camp lead', phone: '+91 253 000 0012' },
    startDateTime: new Date(now - 2 * DAY),
    endDateTime: new Date(now - 1 * DAY),
  },
];

const PROFILE = {
  phone: '+91 98220 00001',
  address: 'Panchavati, Nashik',
  city: 'Nashik',
  emergencyContactName: 'Demo contact',
  emergencyContactPhone: '+91 98220 00002',
};

const VOLUNTEERS = [
  {
    name: 'Demo Volunteer Ravi',
    email: 'demo.ravi@medaid.test',
    username: 'demo_ravi',
    location: near(300, 200),
    verificationStatus: VERIFICATION_STATUS.APPROVED,
    status: VOLUNTEER_STATUS.ACTIVE,
    skills: ['First aid', 'Crowd guidance'],
  },
  {
    name: 'Demo Volunteer Sana',
    email: 'demo.sana@medaid.test',
    username: 'demo_sana',
    location: near(900, -600),
    verificationStatus: VERIFICATION_STATUS.APPROVED,
    status: VOLUNTEER_STATUS.ACTIVE,
    skills: ['Nursing'],
  },
  {
    name: 'Demo Volunteer Imran',
    email: 'demo.imran@medaid.test',
    username: 'demo_imran',
    location: near(2200, 1800),
    verificationStatus: VERIFICATION_STATUS.APPROVED,
    status: VOLUNTEER_STATUS.OFFLINE,
    skills: ['Ambulance driving'],
  },
  {
    // For the verification queue in the admin console.
    name: 'Demo Volunteer Priya (awaiting review)',
    email: 'demo.priya@medaid.test',
    username: 'demo_priya',
    location: null,
    verificationStatus: VERIFICATION_STATUS.PENDING,
    status: VOLUNTEER_STATUS.OFFLINE,
    skills: ['First aid'],
  },
];

async function upsertUser({ name, email, username, role }, passwordHash) {
  const existing = await User.findOne({ email });
  if (existing) {
    existing.set({ name, username, role });
    return existing.save();
  }
  return User.create({ name, email, username, role, passwordHash, preferredLanguage: 'en' });
}

async function seedVolunteers(passwordHash, now) {
  for (const spec of VOLUNTEERS) {
    const user = await upsertUser({ ...spec, role: ROLES.VOLUNTEER }, passwordHash);
    await Volunteer.findOneAndUpdate(
      { userId: user._id },
      {
        $set: {
          verificationStatus: spec.verificationStatus,
          status: spec.status,
          profileCompleted: true,
          profile: { ...PROFILE, skills: spec.skills },
          submittedAt: now,
          verifiedAt: spec.verificationStatus === VERIFICATION_STATUS.APPROVED ? now : undefined,
          ...(spec.location
            ? { currentLocation: point(spec.location), locationUpdatedAt: now }
            : {}),
        },
        $unset: spec.location ? {} : { currentLocation: '', locationUpdatedAt: '' },
      },
      { upsert: true, returnDocument: 'after', setDefaultsOnInsert: true },
    );
  }
}

/** Seeds the demo records. Expects an open database connection. */
async function seedDemoData(now = new Date()) {
  const passwordHash = await hashPassword(DEMO_PASSWORD);

  // Real hospitals come from OpenStreetMap (doc 18), so invented ones would
  // only pollute the map. They are available with SEED_DEMO_HOSPITALS=true for
  // demonstrating without internet access, and are labelled as seed data.
  if (SEED_HOSPITALS) {
    for (const hospital of HOSPITALS) {
      await Hospital.findOneAndUpdate(
        { name: hospital.name },
        {
          $set: {
            ...hospital,
            location: point(hospital.location),
            isActive: true,
            source: { provider: 'DEMO_SEED' },
          },
        },
        { upsert: true, returnDocument: 'after', setDefaultsOnInsert: true },
      );
    }
  }

  for (const camp of camps(now.getTime())) {
    await MedicalCamp.findOneAndUpdate(
      { name: camp.name },
      { $set: { ...camp, location: point(camp.location), isActive: true, isDeleted: false } },
      { upsert: true, returnDocument: 'after', setDefaultsOnInsert: true },
    );
  }

  await seedVolunteers(passwordHash, now);
  await upsertUser(
    {
      name: 'Demo User Asha',
      email: 'demo.asha@medaid.test',
      username: 'demo_asha',
      role: ROLES.USER,
    },
    passwordHash,
  );

  return {
    hospitals: SEED_HOSPITALS ? HOSPITALS.length : 0,
    camps: 3,
    volunteers: VOLUNTEERS.length,
    users: 1,
  };
}

async function main() {
  if (env.isProduction && process.env.SEED_DEMO_FORCE !== 'true') {
    throw new Error('Refusing to seed demo data in production (set SEED_DEMO_FORCE=true to allow)');
  }
  await connectDatabase(env.mongodbUri);
  try {
    const counts = await seedDemoData();
    logger.info(
      { ...counts, password: DEMO_PASSWORD },
      'Demo data ready. Sign in with any demo_* username or demo_asha.',
    );
  } finally {
    await disconnectDatabase();
  }
}

if (require.main === module) {
  main().catch((err) => {
    logger.fatal({ err }, 'Demo seed failed');
    process.exit(1);
  });
}

module.exports = { seedDemoData, DEMO_PASSWORD, CENTER };
