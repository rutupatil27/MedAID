const EARTH_RADIUS_METERS = 6371008.8;

const toRadians = (degrees) => (degrees * Math.PI) / 180;

/** GeoJSON Point from latitude/longitude (GeoJSON order is [lng, lat]). */
function toPoint({ latitude, longitude }) {
  return { type: 'Point', coordinates: [longitude, latitude] };
}

/** `{ latitude, longitude }` from a GeoJSON Point, or null. */
function fromPoint(point) {
  if (!point || !Array.isArray(point.coordinates) || point.coordinates.length !== 2) return null;
  const [longitude, latitude] = point.coordinates;
  return { latitude, longitude };
}

/** Great-circle distance in meters (straight-line fallback, D-010). */
function haversineMeters(a, b) {
  const dLat = toRadians(b.latitude - a.latitude);
  const dLng = toRadians(b.longitude - a.longitude);
  const lat1 = toRadians(a.latitude);
  const lat2 = toRadians(b.latitude);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_METERS * Math.asin(Math.min(1, Math.sqrt(h)));
}

module.exports = { toPoint, fromPoint, haversineMeters };
