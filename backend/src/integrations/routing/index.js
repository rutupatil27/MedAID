const env = require('../../config/env');
const logger = require('../../utils/logger');
const { createHaversineRouting } = require('./haversineRouting');
const { createOpenRouteService } = require('./openRouteService');

/**
 * RoutingService (D-010): the only way the rest of the backend asks for road
 * distances. The primary provider is OpenRouteService when configured; any
 * failure or unroutable pair falls back to the straight-line estimate, so
 * assignment never blocks on routing.
 *
 * Interface:
 *   matrix(origins[], destination) -> [{ distanceMeters, durationSeconds, source }]
 *   route(origin, destination)     -> { distanceMeters, durationSeconds, geometry[], source }
 */
function withFallback(primary, fallback) {
  return {
    name: `${primary.name}+fallback`,

    async matrix(origins, destination) {
      const estimates = await fallback.matrix(origins, destination);
      try {
        const routed = await primary.matrix(origins, destination);
        return routed.map((value, i) => value ?? estimates[i]);
      } catch (err) {
        logger.warn(
          { err: err.message },
          'Routing matrix unavailable; using straight-line fallback',
        );
        return estimates;
      }
    },

    async route(origin, destination) {
      try {
        return await primary.route(origin, destination);
      } catch (err) {
        logger.warn({ err: err.message }, 'Routing unavailable; using straight-line fallback');
        return fallback.route(origin, destination);
      }
    },
  };
}

function createRoutingService(config = env.routing) {
  const fallback = createHaversineRouting({ profile: config.profile });
  if (!config.orsApiKey) return fallback;
  const primary = createOpenRouteService({
    apiKey: config.orsApiKey,
    baseUrl: config.orsBaseUrl,
    profile: config.profile,
    timeoutMs: config.timeoutMs,
  });
  return withFallback(primary, fallback);
}

let routingService = null;

function getRoutingService() {
  routingService ??= createRoutingService();
  return routingService;
}

/** Test seam: replace the routing provider. */
function setRoutingService(replacement) {
  routingService = replacement;
}

module.exports = { getRoutingService, setRoutingService, createRoutingService, withFallback };
