const AppError = require('../../utils/AppError');
const { toPoint } = require('../../utils/geo');
const { VERIFICATION_STATUS, VOLUNTEER_STATUS } = require('../../config/constants');
const volunteerRepository = require('../../repositories/volunteer.repository');
const documentRepository = require('../../repositories/volunteerDocument.repository');
const userRepository = require('../../repositories/user.repository');
const assignmentService = require('../assignment/assignment.service');
const { toVolunteerView, isLocationStale } = require('./volunteer.mapper');

/** Profile fields a volunteer must fill before verification (doc 20). */
const REQUIRED_PROFILE_FIELDS = [
  'phone',
  'address',
  'city',
  'emergencyContactName',
  'emergencyContactPhone',
];

const isProfileComplete = (profile = {}) =>
  REQUIRED_PROFILE_FIELDS.every((field) => String(profile[field] ?? '').trim().length > 0);

async function viewOf(volunteer) {
  const [user, documents] = await Promise.all([
    userRepository.findById(volunteer.userId),
    documentRepository.listCurrent(volunteer._id),
  ]);
  return toVolunteerView(volunteer, user, documents);
}

async function updateProfile(volunteer, changes) {
  const current = volunteer.profile?.toObject?.() ?? {};
  const merged = { ...current, ...changes };
  const updated = await volunteerRepository.updateById(volunteer._id, {
    $set: { profile: merged, profileCompleted: isProfileComplete(merged) },
  });
  return viewOf(updated);
}

/**
 * Active/Offline control (FR-09). Only APPROVED volunteers with a fresh
 * location may go ACTIVE; BUSY volunteers must resolve first (OQ-24).
 */
async function setAvailability(volunteer, { status, latitude, longitude, accuracy }) {
  if (volunteer.status === VOLUNTEER_STATUS.BUSY) {
    throw new AppError('VOLUNTEER_NOT_AVAILABLE', 'Resolve your current emergency first');
  }
  const now = new Date();

  if (status === VOLUNTEER_STATUS.ACTIVE) {
    if (volunteer.verificationStatus !== VERIFICATION_STATUS.APPROVED) {
      throw new AppError('VOLUNTEER_NOT_VERIFIED', 'Verification is not approved');
    }
    const set = { status: VOLUNTEER_STATUS.ACTIVE, statusChangedAt: now, lastActiveAt: now };
    if (latitude != null && longitude != null) {
      Object.assign(set, {
        currentLocation: toPoint({ latitude, longitude }),
        locationAccuracy: accuracy,
        locationUpdatedAt: now,
      });
    } else if (isLocationStale(volunteer)) {
      throw new AppError('LOCATION_UNAVAILABLE', 'A recent location is required to go active');
    }
    const updated = await volunteerRepository.updateById(
      volunteer._id,
      { $set: set },
      { where: { status: { $ne: VOLUNTEER_STATUS.BUSY } } },
    );
    if (!updated) throw new AppError('VOLUNTEER_NOT_AVAILABLE', 'Availability changed meanwhile');
    assignmentService.onVolunteerAvailable();
    return viewOf(updated);
  }

  // OFFLINE: stop tracking and forget the last location (OQ-33).
  const hadReservation = Boolean(volunteer.currentAssignmentId);
  const updated = await volunteerRepository.updateById(
    volunteer._id,
    {
      $set: { status: VOLUNTEER_STATUS.OFFLINE, statusChangedAt: now },
      $unset: { currentLocation: '', locationAccuracy: '', locationUpdatedAt: '' },
    },
    { where: { status: { $ne: VOLUNTEER_STATUS.BUSY } } },
  );
  if (!updated) throw new AppError('VOLUNTEER_NOT_AVAILABLE', 'Availability changed meanwhile');
  if (hadReservation) await assignmentService.handleVolunteerUnavailable(volunteer._id);
  return viewOf(updated);
}

/** Location is tracked only while ACTIVE or BUSY (doc 18). */
async function updateLocation(volunteer, { latitude, longitude, accuracy }) {
  const now = new Date();
  const updated = await volunteerRepository.updateById(
    volunteer._id,
    {
      $set: {
        currentLocation: toPoint({ latitude, longitude }),
        locationAccuracy: accuracy,
        locationUpdatedAt: now,
        lastActiveAt: now,
      },
    },
    { where: { status: { $in: [VOLUNTEER_STATUS.ACTIVE, VOLUNTEER_STATUS.BUSY] } } },
  );
  if (!updated) {
    throw new AppError('VOLUNTEER_NOT_AVAILABLE', 'Location is only shared while active or busy');
  }
  return { location: toVolunteerView(updated, null).location };
}

module.exports = {
  REQUIRED_PROFILE_FIELDS,
  isProfileComplete,
  viewOf,
  updateProfile,
  setAvailability,
  updateLocation,
};
