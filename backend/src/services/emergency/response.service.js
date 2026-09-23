const AppError = require('../../utils/AppError');
const { withTransaction } = require('../../utils/transaction');
const {
  ASSIGNMENT_STATUS: A,
  EMERGENCY_STATUS: S,
  VERIFICATION_STATUS,
  VOLUNTEER_STATUS,
} = require('../../config/constants');
const emergencyRepository = require('../../repositories/emergency.repository');
const assignmentRepository = require('../../repositories/emergencyAssignment.repository');
const volunteerRepository = require('../../repositories/volunteer.repository');
const userRepository = require('../../repositories/user.repository');
const assignmentService = require('../assignment/assignment.service');
const { endActiveAssignment } = require('../assignment/assignment.lifecycle');
const notificationService = require('../notification/notification.service');
const { toVolunteerView } = require('./emergency.mapper');

const { EVENTS } = notificationService;

function assertApproved(volunteer) {
  if (volunteer.verificationStatus !== VERIFICATION_STATUS.APPROVED) {
    throw new AppError('VOLUNTEER_NOT_VERIFIED', 'Verification is not approved');
  }
}

async function viewFor(emergency, assignment) {
  const reporter = await userRepository.findById(emergency.userId);
  return toVolunteerView(emergency, assignment, reporter);
}

/** Emergencies dispatched to this volunteer: active ones or history. */
async function listForVolunteer(volunteer, { scope, page, limit }) {
  const { items, total } = await assignmentRepository.listForVolunteer(volunteer._id, {
    active: scope === 'ACTIVE',
    page,
    limit,
  });
  const views = await Promise.all(
    items.map(async (assignment) => {
      const emergency = await emergencyRepository.findById(assignment.emergencyId);
      return emergency ? viewFor(emergency, assignment) : null;
    }),
  );
  return { items: views.filter(Boolean), page, limit, total };
}

async function getForVolunteer(volunteer, emergencyId) {
  const assignment = await assignmentRepository.findForVolunteer(emergencyId, volunteer._id);
  const emergency = assignment ? await emergencyRepository.findById(emergencyId) : null;
  // Only volunteers ever dispatched to this emergency may see it (doc 22).
  if (!emergency) throw AppError.notFound('Emergency');
  return viewFor(emergency, assignment);
}

/** Explains why there is no pending assignment for this volunteer. */
async function missingPendingAssignment(volunteer, emergencyId) {
  const latest = await assignmentRepository.findForVolunteer(emergencyId, volunteer._id);
  if (!latest) return AppError.notFound('Emergency');
  if (latest.status === A.EXPIRED) return new AppError('ASSIGNMENT_EXPIRED', 'Assignment expired');
  return new AppError(
    'EMERGENCY_ALREADY_ASSIGNED',
    'This emergency is no longer awaiting your response',
  );
}

/**
 * Atomic acceptance (D-009). Every step is a conditional update inside one
 * transaction: the assignment must still be PENDING and unexpired, the
 * emergency must still be ASSIGNED to this volunteer, and the volunteer must
 * still be ACTIVE and reserved for it. Otherwise nothing changes.
 */
async function accept(volunteer, emergencyId) {
  assertApproved(volunteer);

  const existing = await assignmentRepository.findForVolunteer(emergencyId, volunteer._id);
  if (existing?.status === A.ACCEPTED) {
    // Double tap / retry: already accepted by this volunteer.
    return viewFor(await emergencyRepository.findById(emergencyId), existing);
  }

  const now = new Date();
  const result = await withTransaction(async (session) => {
    const pending = await assignmentRepository.findForVolunteer(emergencyId, volunteer._id, {
      status: A.PENDING,
      session,
    });
    if (!pending) throw await missingPendingAssignment(volunteer, emergencyId);

    const assignment = await assignmentRepository.transition(
      pending._id,
      {
        from: [A.PENDING],
        to: A.ACCEPTED,
        set: { acceptedAt: now },
        where: { expiresAt: { $gt: now } },
      },
      session,
    );
    if (!assignment) throw new AppError('ASSIGNMENT_EXPIRED', 'Assignment expired');

    const emergency = await emergencyRepository.transition(
      emergencyId,
      {
        from: [S.ASSIGNED],
        to: S.ACCEPTED,
        set: { acceptedAt: now },
        where: { assignedVolunteerId: volunteer._id, currentAssignmentId: pending._id },
        by: volunteer.userId,
      },
      session,
    );
    if (!emergency) {
      throw new AppError(
        'EMERGENCY_ALREADY_ASSIGNED',
        'Emergency is no longer awaiting acceptance',
      );
    }

    const busy = await volunteerRepository.updateById(
      volunteer._id,
      { $set: { status: VOLUNTEER_STATUS.BUSY, statusChangedAt: now, lastActiveAt: now } },
      { session, where: { status: VOLUNTEER_STATUS.ACTIVE, currentAssignmentId: pending._id } },
    );
    if (!busy) throw new AppError('VOLUNTEER_NOT_AVAILABLE', 'You are no longer available');

    return { emergency, assignment };
  });

  const data = { emergencyId: result.emergency.id };
  await notificationService.notify({
    type: EVENTS.EMERGENCY_ACCEPTED,
    recipients: [result.emergency.userId],
    data,
  });
  await notificationService.notifyAdmins({ type: EVENTS.EMERGENCY_ACCEPTED, data });
  return viewFor(result.emergency, result.assignment);
}

/** Declining hands the emergency straight back to the engine (OQ-21). */
async function decline(volunteer, emergencyId, { reason } = {}) {
  const now = new Date();
  const result = await withTransaction(async (session) => {
    const pending = await assignmentRepository.findForVolunteer(emergencyId, volunteer._id, {
      status: A.PENDING,
      session,
    });
    if (!pending) throw await missingPendingAssignment(volunteer, emergencyId);

    const assignment = await assignmentRepository.transition(
      pending._id,
      {
        from: [A.PENDING],
        to: A.DECLINED,
        set: { declinedAt: now, endReason: reason || 'DECLINED' },
      },
      session,
    );
    if (!assignment) throw await missingPendingAssignment(volunteer, emergencyId);

    const emergency = await emergencyRepository.transition(
      emergencyId,
      {
        from: [S.ASSIGNED],
        to: S.ASSIGNING,
        set: { assignedVolunteerId: null, currentAssignmentId: null, assignmentLockUntil: null },
        addToSet: { excludedVolunteerIds: volunteer._id },
        where: { currentAssignmentId: pending._id },
        by: volunteer.userId,
        note: 'DECLINED',
      },
      session,
    );
    await volunteerRepository.releaseReservation(volunteer._id, emergencyId, session);
    return { emergency, assignment };
  });

  if (result.emergency) {
    await notificationService.notifyAdmins({
      type: EVENTS.EMERGENCY_REASSIGNING,
      data: { emergencyId: result.emergency.id },
    });
    assignmentService.requestAssignment(result.emergency._id);
  }
  return viewFor(
    result.emergency ?? (await emergencyRepository.findById(emergencyId)),
    result.assignment,
  );
}

/** "Arrived / started assistance" (OQ-22). */
async function start(volunteer, emergencyId) {
  const emergency = await emergencyRepository.transition(emergencyId, {
    from: [S.ACCEPTED],
    to: S.IN_PROGRESS,
    set: { startedAt: new Date() },
    where: { assignedVolunteerId: volunteer._id },
    by: volunteer.userId,
  });
  if (!emergency) throw await notRespondingTo(volunteer, emergencyId);

  await notificationService.notify({
    type: EVENTS.EMERGENCY_IN_PROGRESS,
    recipients: [emergency.userId],
    data: { emergencyId: emergency.id },
  });
  const assignment = await assignmentRepository.findById(emergency.currentAssignmentId);
  return viewFor(emergency, assignment);
}

async function notRespondingTo(volunteer, emergencyId) {
  const emergency = await emergencyRepository.findById(emergencyId);
  if (!emergency || emergency.assignedVolunteerId?.toString() !== volunteer.id) {
    return AppError.notFound('Emergency');
  }
  return AppError.conflict('Emergency is not in a state that allows this action');
}

/** Resolution frees the volunteer: BUSY -> ACTIVE (FR-12). */
async function resolve(volunteer, emergencyId, { resolutionNote }) {
  const now = new Date();
  const result = await withTransaction(async (session) => {
    const emergency = await emergencyRepository.transition(
      emergencyId,
      {
        from: [S.ACCEPTED, S.IN_PROGRESS],
        to: S.RESOLVED,
        set: { resolvedAt: now, resolvedBy: volunteer.userId, resolutionNote },
        where: { assignedVolunteerId: volunteer._id },
        by: volunteer.userId,
        note: 'RESOLVED',
      },
      session,
    );
    if (!emergency) return null;
    const released = await endActiveAssignment(
      emergency,
      { assignmentStatus: A.COMPLETED, reason: 'RESOLVED' },
      session,
    );
    return { emergency, released };
  });
  if (!result) throw await notRespondingTo(volunteer, emergencyId);

  const data = { emergencyId: result.emergency.id };
  await notificationService.notify({
    type: EVENTS.EMERGENCY_RESOLVED,
    recipients: [result.emergency.userId],
    data,
  });
  await notificationService.notifyAdmins({ type: EVENTS.EMERGENCY_RESOLVED, data });
  assignmentService.onVolunteerAvailable();

  const assignment = await assignmentRepository.findById(result.emergency.currentAssignmentId);
  return viewFor(result.emergency, assignment);
}

module.exports = { listForVolunteer, getForVolunteer, accept, decline, start, resolve };
