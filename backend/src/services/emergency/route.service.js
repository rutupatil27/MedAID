const AppError = require('../../utils/AppError');
const { fromPoint } = require('../../utils/geo');
const emergencyRepository = require('../../repositories/emergency.repository');
const assignmentRepository = require('../../repositories/emergencyAssignment.repository');
const { getRoutingService } = require('../../integrations/routing');

/**
 * Route and ETA for the volunteer's response map (P-20). The routing key stays
 * on the backend; the app only receives geometry and summary metrics.
 *
 * Results are cached briefly per emergency and origin (rounded to ~11 m) so
 * polling clients do not exhaust the OpenRouteService quota.
 */
const CACHE_TTL_MS = 60 * 1000;
const CACHE_MAX_ENTRIES = 500;
const cache = new Map();

const round = (value) => value.toFixed(4);

function cacheKey(emergencyId, origin) {
  return `${emergencyId}|${round(origin.latitude)},${round(origin.longitude)}`;
}

function remember(key, view, now) {
  if (cache.size >= CACHE_MAX_ENTRIES) cache.delete(cache.keys().next().value);
  cache.set(key, { view, expiresAt: now.getTime() + CACHE_TTL_MS });
}

/** Only the volunteer holding the emergency's active assignment gets a route. */
async function routeForVolunteer(volunteer, emergencyId, now = new Date()) {
  const assignment = await assignmentRepository.findActiveForEmergency(emergencyId);
  if (!assignment?.volunteerId.equals(volunteer._id)) throw AppError.notFound('Active assignment');

  const emergency = await emergencyRepository.findById(emergencyId);
  if (!emergency?.location) {
    throw new AppError('LOCATION_UNAVAILABLE', 'The emergency has no location');
  }
  if (!volunteer.currentLocation) {
    throw new AppError('LOCATION_UNAVAILABLE', 'Share your location to see the route');
  }

  const origin = fromPoint(volunteer.currentLocation);
  const destination = fromPoint(emergency.location);
  const key = cacheKey(emergencyId, origin);
  const cached = cache.get(key);
  if (cached && cached.expiresAt > now.getTime()) return cached.view;

  const route = await getRoutingService().route(origin, destination);
  const view = {
    origin,
    destination,
    distanceMeters: route.distanceMeters,
    durationSeconds: route.durationSeconds,
    source: route.source,
    geometry: route.geometry,
    originUpdatedAt: volunteer.locationUpdatedAt ?? null,
    computedAt: now,
  };
  remember(key, view, now);
  return view;
}

module.exports = { routeForVolunteer };
