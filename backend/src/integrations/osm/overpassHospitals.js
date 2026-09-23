const env = require('../../config/env');

/**
 * Real hospitals and clinics from OpenStreetMap, through the Overpass API
 * (doc 18: the map data already comes from OSM).
 *
 *   findHospitals({ latitude, longitude, radiusMeters }) -> [hospital]
 *
 * Overpass is a shared, rate-limited public service, so callers must cache
 * (see facility/osmHospitals.service.js) and must keep working when it is
 * slow or unavailable.
 */
const AMENITIES = '^(hospital|clinic)$';

/**
 * Overpass answers 406 to requests that do not identify themselves, and the
 * OpenStreetMap usage policy requires it.
 */
const USER_AGENT = 'MedAID/1.0 (emergency health assistance app)';

const firstOf = (tags, keys) => keys.map((key) => tags[key]).find((value) => value);

function addressOf(tags) {
  const full = firstOf(tags, ['addr:full', 'address']);
  if (full) return full;
  const parts = [
    [tags['addr:housenumber'], tags['addr:street']].filter(Boolean).join(' '),
    tags['addr:suburb'],
    tags['addr:city'] ?? tags['addr:town'] ?? tags['addr:village'],
  ].filter(Boolean);
  return parts.length > 0 ? parts.join(', ') : undefined;
}

/** Places mapped as closed or gone: never show them as somewhere to go. */
function isClosed(tags) {
  return (
    tags['disused:amenity'] != null ||
    tags['abandoned:amenity'] != null ||
    tags['was:amenity'] != null ||
    tags['demolished:building'] != null ||
    tags.operational_status === 'closed' ||
    tags.disused === 'yes'
  );
}

/** Keeps only what the app shows; OSM has hundreds of tags we do not need. */
function toHospital(element) {
  const tags = element.tags ?? {};
  const latitude = element.lat ?? element.center?.lat;
  const longitude = element.lon ?? element.center?.lon;
  const name = tags.name ?? tags['name:en'];
  if (!name || latitude == null || longitude == null || isClosed(tags)) return null;

  return {
    name: name.slice(0, 160),
    location: { latitude, longitude },
    address: addressOf(tags)?.slice(0, 300),
    phone: firstOf(tags, ['phone', 'contact:phone', 'contact:mobile'])?.slice(0, 20),
    // OSM marks emergency departments explicitly; clinics rarely have one.
    hasEmergencyDepartment: tags.emergency === 'yes',
    services: [tags.amenity === 'clinic' ? 'Clinic' : 'Hospital'],
    externalId: `${element.type}/${element.id}`,
  };
}

function createOverpassHospitals(config = env.osm) {
  return {
    name: 'overpass',

    /**
     * Everything in the area, never a capped slice: Overpass has no notion of
     * "nearest", so `out ... N` returns an arbitrary N and would hide the
     * hospital across the street. The caller sorts by distance and decides how
     * many to keep. Asking for all of them costs the same.
     */
    async findHospitals({ latitude, longitude, radiusMeters }, fetchImpl = fetch) {
      const area = `(around:${Math.round(radiusMeters)},${latitude},${longitude})`;
      const query = `[out:json][timeout:${Math.round(config.timeoutMs / 1000)}];
(
  node["amenity"~"${AMENITIES}"]${area};
  way["amenity"~"${AMENITIES}"]${area};
  relation["amenity"~"${AMENITIES}"]${area};
);
out center tags;`;

      // Public Overpass servers are often busy (504) or rate limited (429),
      // so try the mirrors in turn before giving up.
      const endpoints = config.overpassUrl
        .split(',')
        .map((url) => url.trim())
        .filter(Boolean);
      let lastError;
      for (const endpoint of endpoints) {
        try {
          const response = await fetchImpl(endpoint, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              Accept: 'application/json',
              'User-Agent': USER_AGENT,
            },
            body: `data=${encodeURIComponent(query)}`,
            signal: AbortSignal.timeout(config.timeoutMs),
          });
          if (!response.ok) throw new Error(`Overpass responded with ${response.status}`);

          const data = await response.json();
          return (data.elements ?? []).map(toHospital).filter(Boolean);
        } catch (error) {
          lastError = error;
        }
      }
      throw lastError ?? new Error('No Overpass endpoint configured');
    },
  };
}

let provider = null;

function getHospitalDirectory() {
  provider ??= createOverpassHospitals();
  return provider;
}

/** Test seam: replace the directory provider. */
function setHospitalDirectory(replacement) {
  provider = replacement;
}

module.exports = {
  createOverpassHospitals,
  getHospitalDirectory,
  setHospitalDirectory,
  toHospital,
  USER_AGENT,
};
