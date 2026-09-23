const AppError = require('../../utils/AppError');
const { toPoint } = require('../../utils/geo');
const { withTransaction } = require('../../utils/transaction');
const { APP_TIMEZONE, EMERGENCY_STATUS: S, ASSIGNMENT_STATUS } = require('../../config/constants');
const emergencyRepository = require('../../repositories/emergency.repository');
const counterRepository = require('../../repositories/counter.repository');
const volunteerRepository = require('../../repositories/volunteer.repository');
const assignmentRepository = require('../../repositories/emergencyAssignment.repository');
const assignmentService = require('../assignment/assignment.service');
const { endActiveAssignment } = require('../assignment/assignment.lifecycle');
const notificationService = require('../notification/notification.service');
const { toUserView } = require('./emergency.mapper');

const { EVENTS } = notificationService;

const USER_CANCELLABLE = [
  S.CREATED,
  S.ASSIGNING,
  S.ASSIGNED,
  S.ACCEPTED,
  S.IN_PROGRESS,
  S.UNASSIGNED,
];
const RESPONDER_VISIBLE = [S.ACCEPTED, S.IN_PROGRESS, S.RESOLVED];

const dayFormatter = new Intl.DateTimeFormat('en-CA', {
  timeZone: APP_TIMEZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});

/** Human-readable, per-day sequence, e.g. MED-20260917-0042. */
async function nextAlertNumber(now = new Date()) {
  const day = dayFormatter.format(now).replaceAll('-', '');
  const seq = await counterRepository.nextSequence(`alert-${day}`);
  return `MED-${day}-${String(seq).padStart(4, '0')}`;
}

/**
 * One-tap SOS (FR-05). Idempotent: a repeated request (same Idempotency-Key)
 * or a second SOS while one is open returns the existing emergency (P-08).
 * @returns {Promise<{ emergency: object, created: boolean }>}
 */
async function createEmergency(userId, input, { idempotencyKey } = {}) {
  if (idempotencyKey) {
    const replay = await emergencyRepository.findByIdempotencyKey(userId, idempotencyKey);
    if (replay) return { emergency: replay, created: false };
  }
  const open = await emergencyRepository.findOpenByUser(userId);
  if (open) return { emergency: open, created: false };

  const hasLocation = input.latitude != null && input.longitude != null;
  let emergency;
  try {
    emergency = await emergencyRepository.create({
      alertNumber: await nextAlertNumber(),
      userId,
      location: hasLocation ? toPoint(input) : undefined,
      locationAccuracy: hasLocation ? input.accuracy : undefined,
      message: input.message || undefined,
      idempotencyKey,
      status: S.CREATED,
      statusHistory: [{ status: S.CREATED, at: new Date(), by: userId }],
    });
  } catch (err) {
    // Lost a race with a concurrent SOS from the same user: return the winner.
    if (err?.code === 11000) {
      const winner = await emergencyRepository.findOpenByUser(userId);
      if (winner) return { emergency: winner, created: false };
    }
    throw err;
  }

  const data = { emergencyId: emergency.id };
  await notificationService.notify({ type: EVENTS.EMERGENCY_CREATED, recipients: [userId], data });
  await notificationService.notifyAdmins({ type: EVENTS.EMERGENCY_CREATED, data });
  assignmentService.requestAssignment(emergency._id);

  return { emergency, created: true };
}

async function responderFor(emergency) {
  if (!RESPONDER_VISIBLE.includes(emergency.status) || !emergency.assignedVolunteerId) return null;
  const [volunteer, assignment] = await Promise.all([
    volunteerRepository.findById(emergency.assignedVolunteerId).populate('userId', 'name'),
    emergency.currentAssignmentId
      ? assignmentRepository.findById(emergency.currentAssignmentId)
      : null,
  ]);
  return {
    name: volunteer?.userId?.name ?? null,
    estimatedDurationSeconds: assignment?.estimatedDurationSeconds ?? null,
    routeDistanceMeters: assignment?.routeDistanceMeters ?? null,
  };
}

async function toDetailedUserView(emergency) {
  return toUserView(emergency, await responderFor(emergency));
}

async function findOwned(userId, emergencyId) {
  const emergency = await emergencyRepository.findById(emergencyId);
  // 404 (not 403) so other users' alert IDs are not revealed (doc 22).
  if (!emergency || emergency.userId.toString() !== userId.toString()) {
    throw AppError.notFound('Emergency');
  }
  return emergency;
}

async function listForUser(userId, { page, limit, open }) {
  const { items, total } = await emergencyRepository.listByUser(userId, { page, limit, open });
  return { items: items.map((e) => toUserView(e)), page, limit, total };
}

async function getForUser(userId, emergencyId) {
  return toDetailedUserView(await findOwned(userId, emergencyId));
}

async function cancelByUser(userId, emergencyId, { reason } = {}) {
  await findOwned(userId, emergencyId);

  const result = await withTransaction(async (session) => {
    const cancelled = await emergencyRepository.transition(
      emergencyId,
      {
        from: USER_CANCELLABLE,
        to: S.CANCELLED,
        set: {
          cancelledAt: new Date(),
          cancelledBy: userId,
          cancelReason: reason,
          assignmentLockUntil: null,
        },
        by: userId,
        note: reason,
      },
      session,
    );
    if (!cancelled) return null;
    const released = await endActiveAssignment(
      cancelled,
      { assignmentStatus: ASSIGNMENT_STATUS.CANCELLED, reason: 'EMERGENCY_CANCELLED_BY_USER' },
      session,
    );
    return { cancelled, released };
  });

  if (!result) throw AppError.conflict('Emergency can no longer be cancelled');

  const data = { emergencyId: result.cancelled.id };
  if (result.released.volunteer) {
    await notificationService.notify({
      type: EVENTS.ASSIGNMENT_CANCELLED,
      recipients: [result.released.volunteer.userId],
      data,
    });
  }
  await notificationService.notifyAdmins({ type: EVENTS.EMERGENCY_CANCELLED, data });

  return toDetailedUserView(result.cancelled);
}

module.exports = {
  USER_CANCELLABLE,
  nextAlertNumber,
  createEmergency,
  listForUser,
  getForUser,
  cancelByUser,
  toDetailedUserView,
};
