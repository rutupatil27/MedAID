const { Emergency } = require('../models');
const { TERMINAL_EMERGENCY_STATUSES, OPEN_EMERGENCY_STATUSES } = require('../config/constants');

function create(data) {
  return Emergency.create(data);
}

function findById(id, session = null) {
  return Emergency.findById(id).session(session);
}

function findOpenByUser(userId) {
  return Emergency.findOne({ userId, isOpen: true });
}

function findByIdempotencyKey(userId, idempotencyKey) {
  return Emergency.findOne({ userId, idempotencyKey });
}

async function listByUser(userId, { page, limit, open }) {
  const filter = { userId };
  if (open !== undefined) filter.isOpen = open;
  const [items, total] = await Promise.all([
    Emergency.find(filter)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit),
    Emergency.countDocuments(filter),
  ]);
  return { items, total };
}

/**
 * Atomic status transition: succeeds only if the emergency is currently in one
 * of `from` (plus any `where` conditions). Keeps `isOpen` and the history in sync.
 * @returns the updated emergency, or null when the precondition no longer holds.
 */
async function transition(
  id,
  { from, to, set = {}, unset, addToSet, where = {}, by, note },
  session = null,
) {
  const now = new Date();
  const update = {
    $set: { ...set, status: to, isOpen: !TERMINAL_EMERGENCY_STATUSES.includes(to) },
  };
  if (unset) update.$unset = unset;
  if (addToSet) update.$addToSet = addToSet;

  const filter = { _id: id, status: { $in: from }, ...where };
  const options = { returnDocument: 'after', session };
  const withHistory = { ...update, $push: { statusHistory: { status: to, at: now, by, note } } };

  // Some transitions allow the status they move to — admin reassignment can be
  // applied to an emergency that is already ASSIGNING. Nothing changes then, so
  // no history entry is written: two identical rows seconds apart look like a
  // bug to whoever reads the timeline, and say nothing that the first did not.
  if (from.includes(to)) {
    const changed = await Emergency.findOneAndUpdate(
      { ...filter, status: { $in: from.filter((status) => status !== to) } },
      withHistory,
      options,
    );
    if (changed) return changed;
    return await Emergency.findOneAndUpdate({ ...filter, status: to }, update, options);
  }

  return await Emergency.findOneAndUpdate(filter, withHistory, options);
}

/** Non-status field updates guarded by a filter (e.g. clearing a lock). */
function updateWhere(filter, update, session = null) {
  return Emergency.findOneAndUpdate(filter, update, { returnDocument: 'after', session });
}

function countByStatus(filter = {}) {
  return Emergency.aggregate([
    { $match: filter },
    { $group: { _id: '$status', count: { $sum: 1 } } },
  ]);
}

module.exports = {
  OPEN_EMERGENCY_STATUSES,
  create,
  findById,
  findOpenByUser,
  findByIdempotencyKey,
  listByUser,
  transition,
  updateWhere,
  countByStatus,
};
