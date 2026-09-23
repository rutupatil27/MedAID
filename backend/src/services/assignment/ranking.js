const { fromPoint } = require('../../utils/geo');
const { getRoutingService } = require('../../integrations/routing');

/**
 * Ranks candidates by estimated travel time, then travel distance, then
 * straight-line distance (doc 07). Provider-independent: metrics come from
 * the RoutingService, which already falls back to straight-line estimates.
 *
 * @returns {Promise<Array<{ volunteer, metric: { distanceMeters, durationSeconds, source } }>>}
 */
async function rankCandidates(candidates, destinationPoint) {
  if (candidates.length === 0) return [];
  const destination = fromPoint(destinationPoint);
  const origins = candidates.map((c) => fromPoint(c.currentLocation));
  const metrics = await getRoutingService().matrix(origins, destination);

  const key = (entry) => [
    entry.metric?.durationSeconds ?? Number.POSITIVE_INFINITY,
    entry.metric?.distanceMeters ?? Number.POSITIVE_INFINITY,
    entry.volunteer.straightLineMeters ?? Number.POSITIVE_INFINITY,
  ];

  return candidates
    .map((volunteer, i) => ({ volunteer, metric: metrics[i] ?? null }))
    .sort((a, b) => {
      const [ka, kb] = [key(a), key(b)];
      for (let i = 0; i < ka.length; i += 1) {
        if (ka[i] !== kb[i]) return ka[i] - kb[i];
      }
      return 0;
    });
}

module.exports = { rankCandidates };
