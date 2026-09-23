const request = require('supertest');
const { createApp } = require('../../src/app');
const { Hospital } = require('../../src/models');
const {
  toHospital,
  setHospitalDirectory,
} = require('../../src/integrations/osm/overpassHospitals');
const osmSync = require('../../src/services/facility/osmHospitals.service');
const { useTestDatabase } = require('../helpers/db');
const { createAccount } = require('../helpers/factories');
const { CENTER, north } = require('../helpers/scenario');

/** What Overpass gives back for a node. */
const element = (id, name, point, extra = {}) => ({
  type: 'node',
  id,
  lat: point.latitude,
  lon: point.longitude,
  tags: { amenity: 'hospital', name, ...extra },
});

describe('Hospitals from OpenStreetMap', () => {
  useTestDatabase();
  const app = createApp();
  let directory;

  beforeEach(() => {
    osmSync.resetSyncCache();
    osmSync.setSyncEnabled(true);
    directory = {
      name: 'fake',
      findHospitals: jest.fn(async () => [
        toHospital(element(1, 'Nashik City Hospital', north(400), { emergency: 'yes' })),
        toHospital(element(2, 'Panchavati Clinic', north(900), { amenity: 'clinic' })),
      ]),
    };
    setHospitalDirectory(directory);
  });

  afterEach(async () => {
    await osmSync.whenSynced();
    osmSync.setSyncEnabled(false);
  });

  const nearby = async (auth, type = 'ALL') => {
    const res = await request(app)
      .get(
        `/api/v1/facilities/nearby?latitude=${CENTER.latitude}&longitude=${CENTER.longitude}&type=${type}`,
      )
      .set('Authorization', auth);
    await osmSync.whenSynced();
    return res;
  };

  it('fills an empty map with real hospitals near the person', async () => {
    const { auth } = await createAccount();

    const res = await nearby(auth);

    expect(res.status).toBe(200);
    expect(res.body.data.map((f) => f.name)).toEqual(['Nashik City Hospital', 'Panchavati Clinic']);
    expect(res.body.data[0]).toMatchObject({ type: 'HOSPITAL', hasEmergencyDepartment: true });
    expect(directory.findHospitals).toHaveBeenCalledTimes(1);
  });

  it('asks for every place in the area and keeps the nearest first', async () => {
    // Overpass cannot sort or return "the nearest N": asking it for a slice
    // returns an arbitrary one, which once hid hospitals a few hundred metres
    // away behind others kilometres out.
    const hospitalRepository = require('../../src/repositories/hospital.repository');
    const stored = jest.spyOn(hospitalRepository, 'bulkUpsertFromOsm');
    directory.findHospitals.mockResolvedValueOnce([
      toHospital(element(10, 'Far Hospital', north(9000))),
      toHospital(element(11, 'Near Hospital', north(200))),
      toHospital(element(12, 'Middle Hospital', north(2500))),
    ]);
    const { auth } = await createAccount();

    await nearby(auth);

    const [, options] = directory.findHospitals.mock.calls[0];
    expect(options).toBeUndefined(); // no limit is passed to the directory
    expect(stored.mock.calls[0][0].map((h) => h.name)).toEqual([
      'Near Hospital',
      'Middle Hospital',
      'Far Hospital',
    ]);
    stored.mockRestore();
  });

  it('asks OpenStreetMap once per area, however many people look', async () => {
    const { auth } = await createAccount();
    const other = await createAccount();

    await nearby(auth);
    await nearby(other.auth);
    await nearby(auth);

    expect(directory.findHospitals).toHaveBeenCalledTimes(1);
    expect(await Hospital.countDocuments()).toBe(2);
  });

  it('updates the same place instead of adding it again', async () => {
    const { auth } = await createAccount();
    await nearby(auth);

    directory.findHospitals.mockResolvedValueOnce([
      toHospital(element(1, 'Nashik City Hospital (renamed)', north(400), { phone: '+91 253 1' })),
    ]);
    osmSync.resetSyncCache();
    await nearby(auth);

    const stored = await Hospital.find({ 'source.provider': 'OSM' });
    expect(stored).toHaveLength(2);
    expect(stored.find((h) => h.source.externalId === 'node/1')).toMatchObject({
      name: 'Nashik City Hospital (renamed)',
      contact: expect.objectContaining({ phone: '+91 253 1' }),
    });
  });

  it('leaves hospitals entered by an admin alone', async () => {
    const { auth } = await createAccount();
    const manual = await Hospital.create({
      name: 'Control Room Clinic',
      location: { type: 'Point', coordinates: [CENTER.longitude, CENTER.latitude] },
      source: { provider: 'MANUAL' },
    });

    await nearby(auth);

    const stored = await Hospital.findById(manual._id);
    expect(stored).toMatchObject({ name: 'Control Room Clinic' });
    expect(stored.source.provider).toBe('MANUAL');
    expect(await Hospital.countDocuments()).toBe(3);
  });

  it('still answers when OpenStreetMap is unavailable', async () => {
    const { auth } = await createAccount();
    await Hospital.create({
      name: 'Known Hospital',
      location: { type: 'Point', coordinates: [CENTER.longitude, CENTER.latitude] },
      source: { provider: 'DEMO_SEED' },
    });
    directory.findHospitals.mockRejectedValue(new Error('Overpass timed out'));

    const res = await nearby(auth);

    expect(res.status).toBe(200);
    expect(res.body.data.map((f) => f.name)).toEqual(['Known Hospital']);
  });

  it('is skipped entirely when turned off', async () => {
    osmSync.setSyncEnabled(false);
    const { auth } = await createAccount();

    const res = await nearby(auth);

    expect(res.status).toBe(200);
    expect(directory.findHospitals).not.toHaveBeenCalled();
  });

  describe('reading OpenStreetMap data', () => {
    it('keeps only usable places', () => {
      expect(toHospital(element(3, 'With name', CENTER))).toMatchObject({
        name: 'With name',
        externalId: 'node/3',
      });
      // No name, or no position: nothing worth showing on a map.
      expect(
        toHospital({ type: 'node', id: 4, lat: 1, lon: 1, tags: { amenity: 'hospital' } }),
      ).toBeNull();
      expect(toHospital({ type: 'way', id: 5, tags: { name: 'Somewhere' } })).toBeNull();
    });

    it('drops places mapped as closed or gone', () => {
      const closed = [
        { 'disused:amenity': 'hospital' },
        { 'abandoned:amenity': 'clinic' },
        { 'was:amenity': 'hospital' },
        { operational_status: 'closed' },
      ];
      for (const tags of closed) {
        expect(toHospital(element(20, 'Closed Place', CENTER, tags))).toBeNull();
      }
    });

    it('identifies itself to Overpass, which refuses anonymous callers', async () => {
      const {
        createOverpassHospitals,
        USER_AGENT,
      } = require('../../src/integrations/osm/overpassHospitals');
      const fetchImpl = jest.fn(async () => ({ ok: true, json: async () => ({ elements: [] }) }));

      await createOverpassHospitals({
        overpassUrl: 'https://overpass.test/api',
        timeoutMs: 5000,
        maxResults: 10,
      }).findHospitals({ latitude: 20, longitude: 73, radiusMeters: 3000 }, fetchImpl);

      const [url, options] = fetchImpl.mock.calls[0];
      expect(url).toBe('https://overpass.test/api');
      expect(options.headers['User-Agent']).toBe(USER_AGENT);
      expect(options.headers['User-Agent']).toMatch(/MedAID/);
      expect(options.body).toContain(encodeURIComponent('around:3000,20,73'));
    });

    it('moves to the next mirror when one is busy', async () => {
      const { createOverpassHospitals } = require('../../src/integrations/osm/overpassHospitals');
      const fetchImpl = jest
        .fn()
        .mockResolvedValueOnce({ ok: false, status: 504 })
        .mockRejectedValueOnce(new Error('timed out'))
        .mockResolvedValueOnce({ ok: true, json: async () => ({ elements: [] }) });

      const found = await createOverpassHospitals({
        overpassUrl: 'https://busy.test/api, https://slow.test/api ,https://spare.test/api',
        timeoutMs: 5000,
      }).findHospitals({ latitude: 20, longitude: 73, radiusMeters: 3000 }, fetchImpl);

      expect(found).toEqual([]);
      expect(fetchImpl.mock.calls.map((call) => call[0])).toEqual([
        'https://busy.test/api',
        'https://slow.test/api',
        'https://spare.test/api',
      ]);
    });

    it('gives up when every mirror fails', async () => {
      const { createOverpassHospitals } = require('../../src/integrations/osm/overpassHospitals');
      const fetchImpl = jest.fn().mockResolvedValue({ ok: false, status: 429 });

      await expect(
        createOverpassHospitals({
          overpassUrl: 'https://a.test/api,https://b.test/api',
          timeoutMs: 5000,
        }).findHospitals({ latitude: 20, longitude: 73, radiusMeters: 3000 }, fetchImpl),
      ).rejects.toThrow('429');
    });

    it('takes the position of an area from its centre', () => {
      const way = {
        type: 'way',
        id: 6,
        center: { lat: 20.1, lon: 73.8 },
        tags: { amenity: 'hospital', name: 'Campus Hospital', 'addr:street': 'Ring Road' },
      };

      expect(toHospital(way)).toMatchObject({
        name: 'Campus Hospital',
        location: { latitude: 20.1, longitude: 73.8 },
        address: 'Ring Road',
        externalId: 'way/6',
      });
    });
  });
});
