const { ASSIGNMENT_STATUS } = require('../../config/constants');
const assignmentRepository = require('../../repositories/emergencyAssignment.repository');
const volunteerRepository = require('../../repositories/volunteer.repository');

const TIMESTAMP_FIELD = Object.freeze({
  [ASSIGNMENT_STATUS.CANCELLED]: 'cancelledAt',
  [ASSIGNMENT_STATUS.COMPLETED]: 'completedAt',
  [ASSIGNMENT_STATUS.EXPIRED]: 'expiredAt',
  [ASSIGNMENT_STATUS.DECLINED]: 'declinedAt',
});

/**
 * Ends an emergency's active assignment (if any) and frees its volunteer:
 * the reservation is cleared and a BUSY volunteer becomes ACTIVE again.
 * Shared by cancellation, resolution and the assignment engine.
 *
 * @param {import('mongoose').Document} emergency
 * @param {{ assignmentStatus: string, reason: string }} options
 * @returns {Promise<{ assignment: object|null, volunteer: object|null }>}
 */
async function endActiveAssignment(emergency, { assignmentStatus, reason }, session = null) {
  const active = await assignmentRepository.findActiveForEmergency(emergency._id, session);

  let assignment = null;
  if (active) {
    assignment = await assignmentRepository.transition(
      active._id,
      {
        from: [ASSIGNMENT_STATUS.PENDING, ASSIGNMENT_STATUS.ACCEPTED],
        to: assignmentStatus,
        set: { [TIMESTAMP_FIELD[assignmentStatus]]: new Date(), endReason: reason },
      },
      session,
    );
  }

  const volunteerId = active?.volunteerId ?? emergency.assignedVolunteerId;
  const volunteer = volunteerId
    ? await volunteerRepository.releaseReservation(volunteerId, emergency._id, session)
    : null;

  return { assignment, volunteer };
}

module.exports = { endActiveAssignment };
