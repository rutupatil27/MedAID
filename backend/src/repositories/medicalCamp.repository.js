const { MedicalCamp } = require('../models');
const { toPoint } = require('../utils/geo');

/**
 * The single definition of "visible to Users right now" (D-012): active, not
 * deleted, and inside its validity window. Expired camps disappear even if
 * isActive is still true.
 */
function currentlyValidFilter(now = new Date()) {
  return {
    isActive: true,
    isDeleted: false,
    startDateTime: { $lte: now },
    endDateTime: { $gte: now },
  };
}

function findNearbyValid({ latitude, longitude, radiusMeters, limit, now = new Date() }) {
  return MedicalCamp.aggregate([
    {
      $geoNear: {
        near: toPoint({ latitude, longitude }),
        distanceField: 'distanceMeters',
        maxDistance: radiusMeters,
        spherical: true,
        query: currentlyValidFilter(now),
      },
    },
    { $limit: limit },
  ]);
}

function findValidById(id, now = new Date()) {
  return MedicalCamp.findOne({ _id: id, ...currentlyValidFilter(now) }).lean();
}

// ---- Admin management (Phase 7) --------------------------------------------

function create(data) {
  return MedicalCamp.create(data);
}

function findById(id) {
  return MedicalCamp.findOne({ _id: id, isDeleted: false });
}

function updateById(id, update) {
  return MedicalCamp.findOneAndUpdate({ _id: id, isDeleted: false }, update, {
    returnDocument: 'after',
    runValidators: true,
  });
}

async function list({ status, search, page, limit, now = new Date() }) {
  const filter = { isDeleted: false };
  if (status === 'ACTIVE_NOW') Object.assign(filter, currentlyValidFilter(now));
  if (status === 'UPCOMING') Object.assign(filter, { isActive: true, startDateTime: { $gt: now } });
  if (status === 'EXPIRED') filter.endDateTime = { $lt: now };
  if (status === 'INACTIVE') filter.isActive = false;
  if (search) filter.name = new RegExp(search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');

  const [items, total] = await Promise.all([
    MedicalCamp.find(filter)
      .sort({ startDateTime: -1 })
      .skip((page - 1) * limit)
      .limit(limit),
    MedicalCamp.countDocuments(filter),
  ]);
  return { items, total };
}

function countCurrentlyValid(now = new Date()) {
  return MedicalCamp.countDocuments(currentlyValidFilter(now));
}

module.exports = {
  currentlyValidFilter,
  findNearbyValid,
  findValidById,
  create,
  findById,
  updateById,
  list,
  countCurrentlyValid,
};
