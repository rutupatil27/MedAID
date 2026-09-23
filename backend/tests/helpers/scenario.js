const { Emergency, EmergencyAssignment, Volunteer } = require('../../src/models');
const { createAccount } = require('./factories');

/** Around Ramkund, Nashik. */
const CENTER = { latitude: 20.0086, longitude: 73.7925 };

const point = ({ latitude, longitude }) => ({ type: 'Point', coordinates: [longitude, latitude] });

/** Offsets a location northwards by roughly `meters`. */
const north = (meters, from = CENTER) => ({
  latitude: from.latitude + meters / 111_320,
  longitude: from.longitude,
});

const COMPLETE_PROFILE = {
  phone: '+91 98220 00000',
  address: 'Panchavati',
  city: 'Nashik',
  emergencyContactName: 'Sita',
  emergencyContactPhone: '+91 98220 11111',
};

/**
 * Creates a VOLUNTEER account + volunteer record. Defaults describe an
 * eligible volunteer: APPROVED, ACTIVE, fresh location at CENTER.
 */
async function createVolunteer({
  verificationStatus = 'APPROVED',
  status = 'ACTIVE',
  location = CENTER,
  locationAgeMs = 0,
  profileCompleted = true,
  accountStatus = 'ACTIVE',
  name,
} = {}) {
  const account = await createAccount({ role: 'VOLUNTEER', accountStatus, name });
  const volunteer = await Volunteer.create({
    userId: account.user._id,
    verificationStatus,
    status,
    profileCompleted,
    profile: profileCompleted ? COMPLETE_PROFILE : {},
    currentLocation: location ? point(location) : undefined,
    locationUpdatedAt: location ? new Date(Date.now() - locationAgeMs) : undefined,
  });
  return { ...account, volunteer };
}

/** An open emergency raised by a new USER account (or `reporter`). */
async function createOpenEmergency({ reporter, location = CENTER, status = 'CREATED' } = {}) {
  const account = reporter ?? (await createAccount());
  const emergency = await Emergency.create({
    alertNumber: `MED-TEST-${Math.random().toString(36).slice(2, 10)}`,
    userId: account.user._id,
    location: location ? point(location) : undefined,
    status,
    statusHistory: [{ status, at: new Date() }],
  });
  return { reporter: account, emergency };
}

/**
 * Simulates the engine dispatching `emergency` to `volunteer`: a PENDING
 * assignment, emergency ASSIGNED, volunteer reserved.
 */
async function dispatch(emergency, volunteer, { expiresInMs = 120_000, attemptNumber = 1 } = {}) {
  const now = Date.now();
  const assignment = await EmergencyAssignment.create({
    emergencyId: emergency._id,
    volunteerId: volunteer._id,
    attemptNumber,
    dispatchedAt: new Date(now),
    expiresAt: new Date(now + expiresInMs),
    routeDistanceMeters: 350,
    estimatedDurationSeconds: 240,
    distanceSource: 'FALLBACK',
  });
  await Emergency.updateOne(
    { _id: emergency._id },
    {
      $set: {
        status: 'ASSIGNED',
        assignedVolunteerId: volunteer._id,
        currentAssignmentId: assignment._id,
        assignedAt: new Date(now),
        attemptCount: attemptNumber,
      },
      $push: { statusHistory: { status: 'ASSIGNED', at: new Date(now) } },
    },
  );
  await Volunteer.updateOne(
    { _id: volunteer._id },
    { $set: { currentAssignmentId: assignment._id, currentEmergencyId: emergency._id } },
  );
  return assignment;
}

module.exports = {
  CENTER,
  COMPLETE_PROFILE,
  point,
  north,
  createVolunteer,
  createOpenEmergency,
  dispatch,
};
