/**
 * OpenRouteService provider (initial road-routing provider, doc 18).
 * The API key stays on the backend (P-20). Coordinates are sent as [lng, lat].
 */
function createOpenRouteService({ apiKey, baseUrl, profile, timeoutMs, fetchImpl = fetch }) {
  async function post(path, body) {
    const response = await fetchImpl(`${baseUrl}${path}`, {
      method: 'POST',
      headers: { Authorization: apiKey, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(timeoutMs),
    });
    if (!response.ok) throw new Error(`OpenRouteService ${path} failed with ${response.status}`);
    return response.json();
  }

  const lngLat = ({ latitude, longitude }) => [longitude, latitude];

  return {
    name: 'openrouteservice',

    /** One {distanceMeters, durationSeconds} per origin (null when unroutable). */
    async matrix(origins, destination) {
      const locations = [...origins.map(lngLat), lngLat(destination)];
      const data = await post(`/v2/matrix/${profile}`, {
        locations,
        sources: origins.map((_, i) => i),
        destinations: [origins.length],
        metrics: ['distance', 'duration'],
      });
      return origins.map((_, i) => {
        const durationSeconds = data.durations?.[i]?.[0];
        const distanceMeters = data.distances?.[i]?.[0];
        if (durationSeconds == null || distanceMeters == null) return null;
        return {
          distanceMeters: Math.round(distanceMeters),
          durationSeconds: Math.round(durationSeconds),
          source: 'ROUTING',
        };
      });
    },

    async route(origin, destination) {
      const data = await post(`/v2/directions/${profile}/geojson`, {
        coordinates: [lngLat(origin), lngLat(destination)],
      });
      const feature = data.features?.[0];
      if (!feature) throw new Error('OpenRouteService returned no route');
      return {
        distanceMeters: Math.round(feature.properties.summary.distance),
        durationSeconds: Math.round(feature.properties.summary.duration),
        geometry: feature.geometry.coordinates.map(([longitude, latitude]) => ({
          latitude,
          longitude,
        })),
        source: 'ROUTING',
      };
    },
  };
}

module.exports = { createOpenRouteService };
