const { haversineMeters } = require('../../utils/geo');

/**
 * Straight-line fallback routing (D-010). Durations are rough estimates:
 * crowded walking speed with a detour factor, clearly flagged as FALLBACK.
 */
const SPEED_METERS_PER_SECOND = { 'foot-walking': 1.2, 'cycling-regular': 3.5, 'driving-car': 6 };
const DETOUR_FACTOR = 1.3;

function createHaversineRouting({ profile = 'foot-walking' } = {}) {
  const speed = SPEED_METERS_PER_SECOND[profile] ?? SPEED_METERS_PER_SECOND['foot-walking'];

  const estimate = (from, to) => {
    const distanceMeters = haversineMeters(from, to) * DETOUR_FACTOR;
    return {
      distanceMeters: Math.round(distanceMeters),
      durationSeconds: Math.round(distanceMeters / speed),
      source: 'FALLBACK',
    };
  };

  return {
    name: 'haversine',

    /** @returns {Promise<Array<{distanceMeters, durationSeconds, source}>>} one per origin */
    async matrix(origins, destination) {
      return origins.map((origin) => estimate(origin, destination));
    },

    async route(origin, destination) {
      return { ...estimate(origin, destination), geometry: [origin, destination] };
    },
  };
}

module.exports = { createHaversineRouting };
