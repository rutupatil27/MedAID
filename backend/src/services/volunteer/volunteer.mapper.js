const env = require('../../config/env');
const { fromPoint } = require('../../utils/geo');
const { REQUIRED_DOCUMENT_TYPES } = require('../../config/constants');

const toId = (value) => (value ? value.toString() : null);

function isLocationStale(volunteer, now = Date.now()) {
  const updatedAt = volunteer.locationUpdatedAt?.getTime();
  return !updatedAt || now - updatedAt > env.assignment.locationStaleMs;
}

function locationView(volunteer) {
  const point = fromPoint(volunteer.currentLocation);
  if (!point) return null;
  return {
    ...point,
    accuracy: volunteer.locationAccuracy ?? null,
    updatedAt: volunteer.locationUpdatedAt ?? null,
    isStale: isLocationStale(volunteer),
  };
}

function documentView(doc) {
  return {
    id: toId(doc._id),
    documentType: doc.documentType,
    status: doc.status,
    originalName: doc.originalName ?? null,
    mimeType: doc.mimeType,
    sizeBytes: doc.sizeBytes,
    uploadedAt: doc.uploadedAt,
    reviewedAt: doc.reviewedAt ?? null,
    reviewNote: doc.reviewNote ?? null,
  };
}

function userSummary(user) {
  if (!user) return null;
  return {
    id: toId(user._id),
    name: user.name,
    email: user.email,
    username: user.username,
    phone: user.phone ?? null,
    accountStatus: user.accountStatus,
    mustChangePassword: Boolean(user.mustChangePassword),
  };
}

/** What a volunteer sees about themself; admins get the same plus audit fields. */
function toVolunteerView(volunteer, user, documents = []) {
  return {
    id: toId(volunteer._id),
    user: userSummary(user),
    profile: volunteer.profile?.toObject?.() ?? volunteer.profile ?? {},
    profileCompleted: Boolean(volunteer.profileCompleted),
    verificationStatus: volunteer.verificationStatus,
    submittedAt: volunteer.submittedAt ?? null,
    verifiedAt: volunteer.verifiedAt ?? null,
    rejectionReason: volunteer.rejectionReason ?? null,
    status: volunteer.status,
    statusChangedAt: volunteer.statusChangedAt ?? null,
    lastActiveAt: volunteer.lastActiveAt ?? null,
    location: locationView(volunteer),
    currentEmergencyId: toId(volunteer.currentEmergencyId),
    requiredDocuments: REQUIRED_DOCUMENT_TYPES,
    documents: documents.map(documentView),
    createdAt: volunteer.createdAt,
  };
}

module.exports = { isLocationStale, locationView, documentView, userSummary, toVolunteerView };
