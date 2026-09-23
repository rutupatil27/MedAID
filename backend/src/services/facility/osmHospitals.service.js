const env = require('../../config/env');
const logger = require('../../utils/logger');
const { haversineMeters } = require('../../utils/geo');
const hospitalRepository = require('../../repositories/hospital.repository');
const { getHospitalDirectory } = require('../../integrations/osm/overpassHospitals');

/**
 * Keeps the hospitals collection stocked with real places from OpenStreetMap
 * around wherever people actually are, so the map is not limited to what an
 * admin typed in.
 *
 * Overpass is a shared public service, so each area is fetched at most once
 * per OSM_CACHE_HOURS. Failures are logged and ignored: the user still gets
 * whatever the database already holds.
 */
let enabled = env.osm.enabled;

const synced = new Map(); // area key -> time of the last successful sync
const inflight = new Map(); // area key -> promise, so parallel requests share one call

/** ~1 km cells: enough to reuse a sync between nearby requests. */
function areaKey({ latitude, longitude, radiusMeters }) {
  return `${latitude.toFixed(2)},${longitude.toFixed(2)},${Math.round(radiusMeters / 1000)}`;
}

function isFresh(key, now) {
  const at = synced.get(key);
  return at != null && now - at < env.osm.cacheHours * 60 * 60 * 1000;
}

async function fetchAndStore(area, key, now) {
  try {
    const found = await getHospitalDirectory().findHospitals(area);
    // Overpass cannot sort, so rank here and keep the closest: a city centre
    // can hold hundreds, and the ones across the street are what matter.
    const hospitals = found
      .map((hospital) => ({ hospital, distance: haversineMeters(area, hospital.location) }))
      .sort((a, b) => a.distance - b.distance)
      .slice(0, env.osm.maxResults)
      .map((entry) => entry.hospital);

    await hospitalRepository.bulkUpsertFromOsm(hospitals);
    synced.set(key, now);
    logger.info(
      { area: key, found: found.length, stored: hospitals.length },
      'Hospitals synced from OpenStreetMap',
    );
  } catch (err) {
    logger.warn({ err: err.message, area: key }, 'Could not sync hospitals from OpenStreetMap');
  } finally {
    inflight.delete(key);
  }
}

/**
 * Makes sure this area has been looked up. The first request for an area waits
 * for it (otherwise the map would look empty); later ones return immediately
 * and any refresh happens in the background.
 */
async function ensureHospitalsNear(area, { now = Date.now() } = {}) {
  if (!enabled) return;
  const key = areaKey(area);
  if (isFresh(key, now)) return;

  const existing = inflight.get(key);
  if (existing) return existing;

  const pending = fetchAndStore(area, key, now);
  inflight.set(key, pending);

  // Nothing stored for this area yet: wait, so the first map is not empty.
  const known = await hospitalRepository.countNear(area);
  if (known === 0) return pending;
  return undefined;
}

/** Resolves once every in-flight sync has finished (tests, shutdown). */
async function whenSynced() {
  while (inflight.size > 0) await Promise.allSettled([...inflight.values()]);
}

/** Test seam: turn the sync on or off at runtime. */
function setSyncEnabled(value) {
  enabled = value;
}

/** Test seam: forget what has been synced. */
function resetSyncCache() {
  synced.clear();
  inflight.clear();
}

module.exports = { ensureHospitalsNear, whenSynced, setSyncEnabled, resetSyncCache, areaKey };
