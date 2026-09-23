const AppError = require('../../utils/AppError');
const { withTransaction } = require('../../utils/transaction');
const {
  ASSIGNMENT_STATUS: A,
  EMERGENCY_STATUS: S,
  OPEN_EMERGENCY_STATUSES,
} = require('../../config/constants');
const { Emergency, User, Volunteer } = require('../../models');
const emergencyRepository = require('../../repositories/emergency.repository');
const assignmentRepository = require('../../repositories/emergencyAssignment.repository');
const assignmentService = require('../assignment/assignment.service');
const { endActiveAssignment } = require('../assignment/assignment.lifecycle');
const notificationService = require('../notification/notification.service');
const { baseView, timeline, assignmentView, toId } = require('../emergency/emergency.mapper');

const { EVENTS } = notificationService;
const escapeRegex = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

async function volunteerSummaries(volunteerIds) {
  const ids = [...new Set(volunteerIds.filter(Boolean).map(String))];
  if (ids.length === 0) return new Map();
  const volunteers = await Volunteer.find({ _id: { $in: ids } }).populate('userId', 'name phone');
  return new Map(
    volunteers.map((v) => [
      v.id,
      { id: v.id, name: v.userId?.name ?? null, phone: v.userId?.phone ?? null, status: v.status },
    ]),
  );
}

/** Admin sees the whole picture, including consented medical information. */
function toAdminView(emergency, { reporter, volunteers, assignments } = {}) {
  const assignedId = toId(emergency.assignedVolunteerId);
  return {
    ...baseView(emergency),
    timeline: timeline(emergency),
    attemptCount: emergency.attemptCount ?? 0,
    resolutionNote: emergency.resolutionNote ?? null,
    cancelReason: emergency.cancelReason ?? null,
    reporter: reporter
      ? {
          id: toId(reporter._id),
          name: reporter.name,
          phone: reporter.phone ?? null,
          medicalProfile: reporter.medicalProfile?.shareWithResponders
            ? (reporter.medicalProfile.toObject?.() ?? reporter.medicalProfile)
            : null,
        }
      : null,
    assignedVolunteer: assignedId ? (volunteers?.get(assignedId) ?? { id: assignedId }) : null,
    assignments: assignments?.map((a) => ({
      ...assignmentView(a),
      volunteer: volunteers?.get(toId(a.volunteerId)) ?? null,
    })),
  };
}

async function list({ status, open, search, page, limit }) {
  const filter = {};
  if (status) filter.status = status;
  if (open !== undefined) filter.isOpen = open;
  if (search) filter.alertNumber = new RegExp(escapeRegex(search), 'i');

  const [items, total] = await Promise.all([
    Emergency.find(filter)
      .sort({ isOpen: -1, createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .populate('userId', 'name phone'),
    Emergency.countDocuments(filter),
  ]);
  const volunteers = await volunteerSummaries(items.map((e) => e.assignedVolunteerId));
  return {
    items: items.map((e) => toAdminView(e, { reporter: e.userId, volunteers })),
    page,
    limit,
    total,
  };
}

async function get(emergencyId) {
  const emergency = await emergencyRepository.findById(emergencyId);
  if (!emergency) throw AppError.notFound('Emergency');
  const [reporter, assignments] = await Promise.all([
    User.findById(emergency.userId),
    assignmentRepository.listForEmergency(emergency._id),
  ]);
  const volunteers = await volunteerSummaries([
    emergency.assignedVolunteerId,
    ...assignments.map((a) => a.volunteerId),
  ]);
  return toAdminView(emergency, { reporter, volunteers, assignments });
}

async function listAssignments(emergencyId) {
  return (await get(emergencyId)).assignments;
}

/**
 * Takes the emergency away from its current volunteer (if any) and returns
 * it to the engine. Used by admin reassignment and by volunteer suspension.
 */
async function releaseForReassignment(emergencyId, { adminUserId, reason }) {
  return withTransaction(async (session) => {
    const current = await emergencyRepository.findById(emergencyId, session);
    if (!current) throw AppError.notFound('Emergency');
    const previousVolunteer = current.assignedVolunteerId;
    const emergency = await emergencyRepository.transition(
      emergencyId,
      {
        from: [S.CREATED, S.ASSIGNING, S.ASSIGNED, S.ACCEPTED, S.IN_PROGRESS, S.UNASSIGNED],
        to: S.ASSIGNING,
        set: { assignedVolunteerId: null, currentAssignmentId: null, assignmentLockUntil: null },
        addToSet: previousVolunteer ? { excludedVolunteerIds: previousVolunteer } : undefined,
        by: adminUserId,
        note: reason,
      },
      session,
    );
    if (!emergency) throw AppError.conflict('Only open emergencies can be reassigned');
    const released = await endActiveAssignment(
      current,
      { assignmentStatus: A.CANCELLED, reason },
      session,
    );
    return { emergency, released };
  });
}

/** Manual reassignment (OQ-25): to a chosen eligible volunteer, or via the engine. */
async function reassign(emergencyId, { volunteerId, adminUserId }) {
  const { emergency, released } = await releaseForReassignment(emergencyId, {
    adminUserId,
    reason: 'ADMIN_REASSIGNED',
  });
  if (released.volunteer) {
    await notificationService.notify({
      type: EVENTS.ASSIGNMENT_CANCELLED,
      recipients: [released.volunteer.userId],
      data: { emergencyId: emergency.id },
    });
  }
  if (volunteerId) {
    await assignmentService.assignManually(emergency._id, volunteerId, { assignedBy: adminUserId });
  } else {
    assignmentService.requestAssignment(emergency._id);
  }
  return get(emergencyId);
}

/** Admin override: close an open emergency with a mandatory note (OQ-25). */
async function close(emergencyId, { to, note, adminUserId }) {
  const now = new Date();
  const set =
    to === S.RESOLVED
      ? {
          resolvedAt: now,
          resolvedBy: adminUserId,
          resolutionNote: note,
          assignmentLockUntil: null,
        }
      : {
          cancelledAt: now,
          cancelledBy: adminUserId,
          cancelReason: note,
          assignmentLockUntil: null,
        };

  const result = await withTransaction(async (session) => {
    const emergency = await emergencyRepository.transition(
      emergencyId,
      { from: OPEN_EMERGENCY_STATUSES, to, set, by: adminUserId, note },
      session,
    );
    if (!emergency) return null;
    const accepted = [S.ACCEPTED, S.IN_PROGRESS].some((s) =>
      emergency.statusHistory.some((h) => h.status === s),
    );
    const released = await endActiveAssignment(
      emergency,
      {
        assignmentStatus: to === S.RESOLVED && accepted ? A.COMPLETED : A.CANCELLED,
        reason: `ADMIN_${to}`,
      },
      session,
    );
    return { emergency, released };
  });
  if (!result) {
    if (!(await emergencyRepository.findById(emergencyId))) throw AppError.notFound('Emergency');
    throw AppError.conflict('Emergency is already closed');
  }

  const data = { emergencyId: result.emergency.id };
  await notificationService.notify({
    type: to === S.RESOLVED ? EVENTS.EMERGENCY_RESOLVED : EVENTS.EMERGENCY_CANCELLED,
    recipients: [result.emergency.userId],
    data,
  });
  if (result.released.volunteer) {
    await notificationService.notify({
      type: EVENTS.ASSIGNMENT_CANCELLED,
      recipients: [result.released.volunteer.userId],
      data,
    });
    assignmentService.onVolunteerAvailable();
  }
  return get(emergencyId);
}

module.exports = {
  toAdminView,
  list,
  get,
  listAssignments,
  releaseForReassignment,
  reassign,
  close,
};
