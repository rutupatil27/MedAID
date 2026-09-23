const mongoose = require('mongoose');
const env = require('../../config/env');
const logger = require('../../utils/logger');
const AppError = require('../../utils/AppError');
const { fromPoint } = require('../../utils/geo');
const { withTransaction } = require('../../utils/transaction');
const { supportsTransactions } = require('../../config/database');
const {
  ACCOUNT_STATUS,
  ASSIGNMENT_STATUS: A,
  EMERGENCY_STATUS: S,
} = require('../../config/constants');
const { Emergency, EmergencyAssignment, User, Volunteer } = require('../../models');
const emergencyRepository = require('../../repositories/emergency.repository');
const assignmentRepository = require('../../repositories/emergencyAssignment.repository');
const volunteerRepository = require('../../repositories/volunteer.repository');
const { getRoutingService } = require('../../integrations/routing');
const notificationService = require('../notification/notification.service');
const { eligibilityFilter, findCandidates } = require('./eligibility');
const { rankCandidates } = require('./ranking');

/**
 * Emergency Assignment Engine (doc 07).
 *
 *   SOS -> claim (short lock) -> eligible candidates -> rank by route metrics
 *       -> atomic reservation + PENDING assignment (2-minute window)
 *       -> accept (response.service) | expire/decline -> next candidate
 *       -> nobody left -> UNASSIGNED + admin escalation, retried later
 *
 * Race safety (D-009, D-022): every step is a conditional update inside a
 * transaction, backed by unique indexes that allow one active assignment per
 * emergency and per volunteer.
 */

const { EVENTS } = notificationService;
const CLAIM_LOCK_MS = 30 * 1000;
const ADMIN_ALERT_INTERVAL_MS = 5 * 60 * 1000;
const CLAIMABLE = [S.CREATED, S.ASSIGNING, S.UNASSIGNED];

class EmergencyChangedError extends Error {}

// ---- Background work tracking (tests and graceful shutdown) -----------------

const inFlight = new Set();

function track(work) {
  const run = work.catch((err) => logger.error({ err }, 'Assignment engine run failed'));
  inFlight.add(run);
  run.finally(() => inFlight.delete(run));
  return run;
}

/** Resolves when all background engine work has finished. */
async function whenIdle() {
  while (inFlight.size > 0) await Promise.allSettled([...inFlight]);
}

const nextTick = () => new Promise((resolve) => setImmediate(resolve));

// ---- Claiming ----------------------------------------------------------------

const lockIsFree = (now) => [{ assignmentLockUntil: null }, { assignmentLockUntil: { $lte: now } }];

/** Takes a short processing lock so only one engine run handles an emergency. */
async function claim(emergencyId, now = new Date()) {
  const lockUntil = new Date(now.getTime() + CLAIM_LOCK_MS);
  const claimed = await emergencyRepository.updateWhere(
    { _id: emergencyId, isOpen: true, status: { $in: CLAIMABLE }, $or: lockIsFree(now) },
    { $set: { assignmentLockUntil: lockUntil } },
  );
  if (!claimed) return null;
  if (claimed.status !== S.CREATED) return { emergency: claimed, lockUntil };

  const moved = await emergencyRepository.transition(emergencyId, {
    from: [S.CREATED],
    to: S.ASSIGNING,
    where: { assignmentLockUntil: lockUntil },
  });
  return moved ? { emergency: moved, lockUntil } : null;
}

function releaseLock(emergencyId, lockUntil) {
  return emergencyRepository.updateWhere(
    { _id: emergencyId, assignmentLockUntil: lockUntil },
    { $set: { assignmentLockUntil: null } },
  );
}

// ---- Dispatch ----------------------------------------------------------------

/**
 * Atomically reserves `volunteerId` (still eligible), creates the PENDING
 * assignment and marks the emergency ASSIGNED. Returns null when the volunteer
 * is no longer available. Throws EmergencyChangedError if the emergency moved on.
 */
async function dispatch(emergency, volunteerId, { metric, lockUntil, assignedBy } = {}) {
  const now = new Date();
  const assignmentId = new mongoose.Types.ObjectId();

  let result;
  try {
    result = await withTransaction(async (session) => {
      const reserved = await volunteerRepository.updateById(
        volunteerId,
        { $set: { currentAssignmentId: assignmentId, currentEmergencyId: emergency._id } },
        { session, where: eligibilityFilter(now) },
      );
      if (!reserved) return null;

      const attemptNumber = (emergency.attemptCount ?? 0) + 1;
      const assignment = await assignmentRepository.create(
        {
          _id: assignmentId,
          emergencyId: emergency._id,
          volunteerId,
          attemptNumber,
          routeDistanceMeters: metric?.distanceMeters,
          estimatedDurationSeconds: metric?.durationSeconds,
          distanceSource: metric?.source,
          dispatchedAt: now,
          expiresAt: new Date(now.getTime() + env.assignment.acceptTimeoutMs),
          assignedBy,
        },
        session,
      );

      const updated = await emergencyRepository.transition(
        emergency._id,
        {
          from: CLAIMABLE,
          to: S.ASSIGNED,
          set: {
            assignedVolunteerId: volunteerId,
            currentAssignmentId: assignmentId,
            assignedAt: now,
            attemptCount: attemptNumber,
            assignmentLockUntil: null,
          },
          where: { assignmentLockUntil: lockUntil },
        },
        session,
      );
      if (!updated) throw new EmergencyChangedError('Emergency changed during dispatch');
      return { emergency: updated, assignment, volunteer: reserved };
    });
  } catch (err) {
    if (!supportsTransactions()) await compensate(volunteerId, assignmentId);
    if (err?.code === 11000) return null; // lost a reservation race
    throw err;
  }
  if (!result) return null;

  const data = { emergencyId: result.emergency.id, assignmentId: result.assignment.id };
  await notificationService.notify({
    type: EVENTS.ASSIGNMENT_NEW,
    recipients: [result.volunteer.userId],
    data,
  });
  await notificationService.notify({
    type: EVENTS.EMERGENCY_ASSIGNED,
    recipients: [result.emergency.userId],
    data: { emergencyId: result.emergency.id },
  });
  return result;
}

/** Without transactions, undo a partial dispatch. */
async function compensate(volunteerId, assignmentId) {
  await Volunteer.updateOne(
    { _id: volunteerId, currentAssignmentId: assignmentId },
    { $set: { currentAssignmentId: null, currentEmergencyId: null } },
  );
  await EmergencyAssignment.deleteOne({ _id: assignmentId, status: A.PENDING });
}

// ---- Unassigned / escalation -------------------------------------------------

async function alertAdmins(emergency, type, reason, now = new Date()) {
  const cutoff = new Date(now.getTime() - ADMIN_ALERT_INTERVAL_MS);
  const due = await emergencyRepository.updateWhere(
    {
      _id: emergency._id,
      $or: [{ lastAdminAlertAt: null }, { lastAdminAlertAt: { $lte: cutoff } }],
    },
    { $set: { lastAdminAlertAt: now } },
  );
  if (due) {
    await notificationService.notifyAdmins({
      type,
      data: { emergencyId: emergency.id, reason },
    });
  }
}

/**
 * Nobody could be dispatched: the emergency stays open as UNASSIGNED (never
 * reported as assigned), admins are alerted, and it is retried later (doc 23).
 */
async function markUnassigned(emergency, lockUntil, reason) {
  let updated;
  if (emergency.status === S.UNASSIGNED) {
    updated = await releaseLock(emergency._id, lockUntil);
  } else {
    updated = await emergencyRepository.transition(emergency._id, {
      from: [S.CREATED, S.ASSIGNING],
      to: S.UNASSIGNED,
      set: { unassignedAt: emergency.unassignedAt ?? new Date(), assignmentLockUntil: null },
      where: { assignmentLockUntil: lockUntil },
      note: reason,
    });
    if (updated) {
      await notificationService.notify({
        type: EVENTS.EMERGENCY_UNASSIGNED,
        recipients: [updated.userId],
        data: { emergencyId: updated.id },
      });
    }
  }
  if (updated) await alertAdmins(updated, EVENTS.EMERGENCY_UNASSIGNED, reason);
  return { outcome: 'UNASSIGNED', reason };
}

// ---- Engine entry points -------------------------------------------------------

/** Finds and dispatches the best eligible volunteer for an open emergency. */
async function processEmergency(emergencyId) {
  const claimed = await claim(emergencyId);
  if (!claimed) return { outcome: 'SKIPPED' };
  const { emergency, lockUntil } = claimed;

  try {
    if (!emergency.location) return await markUnassigned(emergency, lockUntil, 'NO_LOCATION');

    const ranked = await rankCandidates(await findCandidates(emergency), emergency.location);
    for (const { volunteer, metric } of ranked) {
      const result = await dispatch(emergency, volunteer._id, { metric, lockUntil });
      if (result) return { outcome: 'ASSIGNED', ...result };
    }
    return await markUnassigned(
      emergency,
      lockUntil,
      ranked.length > 0 ? 'CANDIDATES_UNAVAILABLE' : 'NO_ELIGIBLE_VOLUNTEER',
    );
  } catch (err) {
    if (err instanceof EmergencyChangedError) return { outcome: 'SKIPPED' };
    await releaseLock(emergency._id, lockUntil);
    throw err;
  }
}

/** Starts assignment for an emergency without blocking the caller. */
function requestAssignment(emergencyId) {
  track(nextTick().then(() => processEmergency(emergencyId)));
}

/**
 * Expires a PENDING assignment (timeout, or the volunteer became unavailable)
 * and immediately tries the next candidate. Loses safely to a concurrent accept.
 */
async function expireAssignment(assignmentId, { reason = 'TIMEOUT', requireDue = true } = {}) {
  const now = new Date();
  const result = await withTransaction(async (session) => {
    const assignment = await assignmentRepository.transition(
      assignmentId,
      {
        from: [A.PENDING],
        to: A.EXPIRED,
        set: { expiredAt: now, endReason: reason },
        where: requireDue ? { expiresAt: { $lte: now } } : {},
      },
      session,
    );
    if (!assignment) return null;
    const emergency = await emergencyRepository.transition(
      assignment.emergencyId,
      {
        from: [S.ASSIGNED],
        to: S.ASSIGNING,
        set: { assignedVolunteerId: null, currentAssignmentId: null, assignmentLockUntil: null },
        addToSet: { excludedVolunteerIds: assignment.volunteerId },
        where: { currentAssignmentId: assignment._id },
        note: reason,
      },
      session,
    );
    const volunteer = await volunteerRepository.releaseReservation(
      assignment.volunteerId,
      assignment.emergencyId,
      session,
    );
    return { assignment, emergency, volunteer };
  });
  if (!result) return null;

  const data = { emergencyId: result.assignment.emergencyId.toString() };
  if (result.volunteer) {
    await notificationService.notify({
      type: EVENTS.ASSIGNMENT_EXPIRED,
      recipients: [result.volunteer.userId],
      data,
    });
  }
  if (result.emergency) {
    await notificationService.notify({
      type: EVENTS.EMERGENCY_REASSIGNING,
      recipients: [result.emergency.userId],
      data,
    });
    await notificationService.notifyAdmins({ type: EVENTS.ASSIGNMENT_EXPIRED, data });
    if (result.emergency.attemptCount >= env.assignment.adminAlertAfterAttempts) {
      await alertAdmins(result.emergency, EVENTS.EMERGENCY_ESCALATED, 'REPEATED_TIMEOUTS');
    }
    await track(processEmergency(result.emergency._id));
  }
  return result;
}

/** Scheduler step: warn about expiring assignments, then expire overdue ones. */
async function runAssignmentScan(now = new Date()) {
  const warnFrom = new Date(now.getTime() + env.assignment.expiryWarningMs);
  const expiring = await EmergencyAssignment.find({
    status: A.PENDING,
    expiryWarningSentAt: null,
    expiresAt: { $gt: now, $lte: warnFrom },
  }).limit(100);
  for (const assignment of expiring) {
    const marked = await EmergencyAssignment.updateOne(
      { _id: assignment._id, expiryWarningSentAt: null },
      { $set: { expiryWarningSentAt: now } },
    );
    if (marked.modifiedCount === 1) {
      const volunteer = await Volunteer.findById(assignment.volunteerId, { userId: 1 });
      if (volunteer) {
        await notificationService.notify({
          type: EVENTS.ASSIGNMENT_EXPIRING,
          recipients: [volunteer.userId],
          data: { emergencyId: assignment.emergencyId.toString(), assignmentId: assignment.id },
        });
      }
    }
  }

  const overdue = await EmergencyAssignment.find({ status: A.PENDING, expiresAt: { $lte: now } })
    .sort({ expiresAt: 1 })
    .limit(100);
  for (const assignment of overdue) await expireAssignment(assignment._id);
}

/** Scheduler step: retry open emergencies still waiting for a volunteer (OQ-29). */
async function retryWaitingEmergencies(now = new Date()) {
  const waiting = await Emergency.find(
    { isOpen: true, status: { $in: CLAIMABLE }, $or: lockIsFree(now) },
    { _id: 1 },
  )
    .sort({ createdAt: 1 })
    .limit(20);
  for (const { _id } of waiting) await processEmergency(_id);
}

/** A volunteer became ACTIVE: waiting emergencies may now be served. */
function onVolunteerAvailable() {
  track(nextTick().then(() => retryWaitingEmergencies()));
}

/** A reserved volunteer went OFFLINE or was suspended before accepting. */
async function handleVolunteerUnavailable(volunteerId) {
  const pending = await EmergencyAssignment.findOne({ volunteerId, status: A.PENDING });
  if (pending) {
    await expireAssignment(pending._id, { reason: 'VOLUNTEER_UNAVAILABLE', requireDue: false });
  }
}

/**
 * Admin manual assignment (OQ-25). The chosen volunteer must still pass every
 * eligibility rule. If they cannot be assigned, the engine takes over and the
 * admin gets VOLUNTEER_NOT_AVAILABLE.
 */
async function assignManually(emergencyId, volunteerId, { assignedBy } = {}) {
  const claimed = await claim(emergencyId);
  if (!claimed) throw AppError.conflict('Emergency is being processed; try again shortly');
  const { emergency, lockUntil } = claimed;

  const fallBackToEngine = async () => {
    await releaseLock(emergency._id, lockUntil);
    requestAssignment(emergency._id);
    throw new AppError('VOLUNTEER_NOT_AVAILABLE', 'The selected volunteer is not eligible');
  };

  const volunteer = await Volunteer.findOne({ _id: volunteerId, ...eligibilityFilter() });
  const account = volunteer && (await User.findById(volunteer.userId, { accountStatus: 1 }));
  if (!volunteer || account?.accountStatus !== ACCOUNT_STATUS.ACTIVE) return fallBackToEngine();

  let metric = null;
  if (emergency.location) {
    [metric] = await getRoutingService().matrix(
      [fromPoint(volunteer.currentLocation)],
      fromPoint(emergency.location),
    );
  }
  try {
    const result = await dispatch(emergency, volunteer._id, { metric, lockUntil, assignedBy });
    if (!result) return fallBackToEngine();
    return result;
  } catch (err) {
    if (err instanceof EmergencyChangedError)
      throw AppError.conflict('Emergency changed meanwhile');
    throw err;
  }
}

module.exports = {
  requestAssignment,
  processEmergency,
  expireAssignment,
  runAssignmentScan,
  retryWaitingEmergencies,
  onVolunteerAvailable,
  handleVolunteerUnavailable,
  assignManually,
  whenIdle,
};
