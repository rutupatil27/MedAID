const { fromPoint } = require('../../utils/geo');

const toId = (value) => (value ? value.toString() : null);

/**
 * Reason codes the app may show against a timeline entry.
 *
 * An emergency retries assignment several times, so a timeline legitimately
 * repeats ASSIGNING and UNASSIGNED. Without the reason those rows are
 * indistinguishable and read as a bug, so the code travels with the entry and
 * the app localizes it.
 *
 * Allow-listed on purpose: `note` also carries free text — a user's
 * cancellation reason, an admin's closing note — which belongs to whoever
 * wrote it and is not repeated into everyone else's timeline (doc 19).
 */
const TIMELINE_REASONS = Object.freeze([
  'NO_LOCATION',
  'NO_ELIGIBLE_VOLUNTEER',
  'CANDIDATES_UNAVAILABLE',
  'VOLUNTEER_UNAVAILABLE',
  'TIMEOUT',
  'DECLINED',
  'ADMIN_REASSIGNED',
]);

const timeline = (emergency) =>
  (emergency.statusHistory ?? []).map((entry) => ({
    status: entry.status,
    at: entry.at,
    reason: TIMELINE_REASONS.includes(entry.note) ? entry.note : null,
  }));

/** Fields every audience may see. */
function baseView(emergency) {
  return {
    id: toId(emergency._id),
    alertNumber: emergency.alertNumber,
    status: emergency.status,
    isOpen: emergency.isOpen,
    location: fromPoint(emergency.location),
    locationAccuracy: emergency.locationAccuracy ?? null,
    message: emergency.message ?? null,
    createdAt: emergency.createdAt,
    updatedAt: emergency.updatedAt,
    assignedAt: emergency.assignedAt ?? null,
    acceptedAt: emergency.acceptedAt ?? null,
    startedAt: emergency.startedAt ?? null,
    resolvedAt: emergency.resolvedAt ?? null,
    cancelledAt: emergency.cancelledAt ?? null,
  };
}

/**
 * What the reporting User sees. Responder details appear only once a
 * volunteer has actually accepted (never claim help that is not coming).
 */
function toUserView(emergency, responder = null) {
  return { ...baseView(emergency), timeline: timeline(emergency), responder };
}

function assignmentView(assignment) {
  if (!assignment) return null;
  return {
    id: toId(assignment._id),
    volunteerId: toId(assignment.volunteerId),
    status: assignment.status,
    attemptNumber: assignment.attemptNumber,
    dispatchedAt: assignment.dispatchedAt,
    expiresAt: assignment.expiresAt,
    acceptedAt: assignment.acceptedAt ?? null,
    declinedAt: assignment.declinedAt ?? null,
    expiredAt: assignment.expiredAt ?? null,
    cancelledAt: assignment.cancelledAt ?? null,
    completedAt: assignment.completedAt ?? null,
    endReason: assignment.endReason ?? null,
    routeDistanceMeters: assignment.routeDistanceMeters ?? null,
    estimatedDurationSeconds: assignment.estimatedDurationSeconds ?? null,
    distanceSource: assignment.distanceSource ?? null,
  };
}

/**
 * What the dispatched volunteer sees. Reporter contact details are shared
 * only while the volunteer is responding, and the medical profile only with
 * the reporter's explicit consent (OQ-16).
 */
function toVolunteerView(emergency, assignment, reporter) {
  const responding = ['PENDING', 'ACCEPTED'].includes(assignment?.status);
  const consent = reporter?.medicalProfile?.shareWithResponders === true;
  return {
    ...baseView(emergency),
    timeline: timeline(emergency),
    resolutionNote: emergency.resolutionNote ?? null,
    assignment: assignmentView(assignment),
    reporter: reporter
      ? {
          name: reporter.name,
          phone: responding ? (reporter.phone ?? null) : null,
          preferredLanguage: reporter.preferredLanguage,
          medicalProfile:
            responding && consent
              ? (reporter.medicalProfile.toObject?.() ?? reporter.medicalProfile)
              : null,
        }
      : null,
  };
}

module.exports = { toId, timeline, baseView, toUserView, assignmentView, toVolunteerView };
