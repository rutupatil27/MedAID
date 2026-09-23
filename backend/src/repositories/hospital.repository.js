const { HOSPITAL_SOURCES } = require('../config/constants');
const { Hospital } = require('../models');
const { toPoint } = require('../utils/geo');

const EARTH_RADIUS_METERS = 6378100;

/** Active hospitals near a point, nearest first, with `distanceMeters`. */
function findNearby({ latitude, longitude, radiusMeters, limit }) {
  return Hospital.aggregate([
    {
      $geoNear: {
        near: toPoint({ latitude, longitude }),
        distanceField: 'distanceMeters',
        maxDistance: radiusMeters,
        spherical: true,
        query: { isActive: true },
      },
    },
    { $limit: limit },
  ]);
}

function findActiveById(id) {
  return Hospital.findOne({ _id: id, isActive: true }).lean();
}

function insertMany(docs) {
  return Hospital.insertMany(docs);
}

function count(filter = {}) {
  return Hospital.countDocuments(filter);
}

/**
 * How many hospitals we already know about in this area. Uses `$geoWithin`
 * because MongoDB does not allow `$near` in a count.
 */
function countNear({ latitude, longitude, radiusMeters }) {
  return Hospital.countDocuments({
    isActive: true,
    location: {
      $geoWithin: { $centerSphere: [[longitude, latitude], radiusMeters / EARTH_RADIUS_METERS] },
    },
  });
}

/**
 * Stores a place found in OpenStreetMap, matched on its OSM id so repeated
 * syncs update rather than duplicate. Hospitals entered by an admin or a seed
 * are never touched, because they carry a different source.
 */
function upsertFromOsm({ externalId, location, phone, ...hospital }) {
  return Hospital.findOneAndUpdate(
    { 'source.provider': HOSPITAL_SOURCES.OSM, 'source.externalId': externalId },
    {
      $set: {
        ...hospital,
        contact: { phone },
        location: toPoint(location),
        isActive: true,
        source: { provider: HOSPITAL_SOURCES.OSM, externalId },
      },
    },
    { upsert: true, returnDocument: 'after', setDefaultsOnInsert: true },
  );
}

/** Stores a whole sync in one round trip; a city centre holds hundreds. */
async function bulkUpsertFromOsm(hospitals) {
  if (hospitals.length === 0) return 0;
  const operations = hospitals.map(({ externalId, location, phone, ...hospital }) => ({
    updateOne: {
      filter: { 'source.provider': HOSPITAL_SOURCES.OSM, 'source.externalId': externalId },
      update: {
        $set: {
          ...hospital,
          contact: { phone },
          location: toPoint(location),
          isActive: true,
          source: { provider: HOSPITAL_SOURCES.OSM, externalId },
        },
      },
      upsert: true,
    },
  }));
  const result = await Hospital.bulkWrite(operations, { ordered: false });
  return result.upsertedCount + result.modifiedCount;
}

module.exports = {
  findNearby,
  findActiveById,
  insertMany,
  count,
  countNear,
  upsertFromOsm,
  bulkUpsertFromOsm,
};
