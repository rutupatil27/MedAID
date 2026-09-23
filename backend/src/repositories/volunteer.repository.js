const { Volunteer } = require('../models');
const { VOLUNTEER_STATUS } = require('../config/constants');

function create(data, session = null) {
  return new Volunteer(data).save({ session });
}

function findById(id, session = null) {
  return Volunteer.findById(id).session(session);
}

function findByUserId(userId, session = null) {
  return Volunteer.findOne({ userId }).session(session);
}

function updateById(id, update, { session = null, where = {} } = {}) {
  return Volunteer.findOneAndUpdate({ _id: id, ...where }, update, {
    returnDocument: 'after',
    runValidators: true,
    session,
  });
}

/**
 * Frees a volunteer from an emergency: clears the reservation and, if they were
 * BUSY with it, returns them to ACTIVE (D-009). No-op if already released.
 */
async function findUserIdsByVerification(verificationStatus) {
  const volunteers = await Volunteer.find({ verificationStatus }, { userId: 1 }).lean();
  return volunteers.map((v) => v.userId);
}

function releaseReservation(volunteerId, emergencyId, session = null) {
  const now = new Date();
  return Volunteer.findOneAndUpdate(
    { _id: volunteerId, currentEmergencyId: emergencyId },
    [
      {
        $set: {
          currentAssignmentId: null,
          currentEmergencyId: null,
          lastActiveAt: now,
          statusChangedAt: {
            $cond: [{ $eq: ['$status', VOLUNTEER_STATUS.BUSY] }, now, '$statusChangedAt'],
          },
          status: {
            $cond: [
              { $eq: ['$status', VOLUNTEER_STATUS.BUSY] },
              VOLUNTEER_STATUS.ACTIVE,
              '$status',
            ],
          },
        },
      },
    ],
    { returnDocument: 'after', session, updatePipeline: true },
  );
}

module.exports = {
  findUserIdsByVerification,
  create,
  findById,
  findByUserId,
  updateById,
  releaseReservation,
};
