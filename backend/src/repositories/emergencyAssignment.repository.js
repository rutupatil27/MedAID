const { EmergencyAssignment } = require('../models');
const { ACTIVE_ASSIGNMENT_STATUSES } = require('../config/constants');

function create(data, session = null) {
  return new EmergencyAssignment(data).save({ session });
}

function findById(id, session = null) {
  return EmergencyAssignment.findById(id).session(session);
}

function findActiveForEmergency(emergencyId, session = null) {
  return EmergencyAssignment.findOne({ emergencyId, isActive: true }).session(session);
}

function listForEmergency(emergencyId) {
  return EmergencyAssignment.find({ emergencyId }).sort({ attemptNumber: 1 });
}

/**
 * Atomic assignment state change: only applies while the assignment is still
 * in one of `from`. `isActive` is derived from the target status.
 */
function transition(id, { from, to, set = {}, where = {} }, session = null) {
  return EmergencyAssignment.findOneAndUpdate(
    { _id: id, status: { $in: from }, ...where },
    { $set: { ...set, status: to, isActive: ACTIVE_ASSIGNMENT_STATUSES.includes(to) } },
    { returnDocument: 'after', session },
  );
}

function findForVolunteer(emergencyId, volunteerId, { status, session = null } = {}) {
  const filter = { emergencyId, volunteerId };
  if (status) filter.status = status;
  return EmergencyAssignment.findOne(filter).sort({ attemptNumber: -1 }).session(session);
}

async function listForVolunteer(volunteerId, { active, page = 1, limit = 20 }) {
  const filter = { volunteerId, isActive: active };
  const [items, total] = await Promise.all([
    EmergencyAssignment.find(filter)
      .sort({ dispatchedAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit),
    EmergencyAssignment.countDocuments(filter),
  ]);
  return { items, total };
}

module.exports = {
  create,
  findById,
  findActiveForEmergency,
  listForEmergency,
  transition,
  findForVolunteer,
  listForVolunteer,
};
