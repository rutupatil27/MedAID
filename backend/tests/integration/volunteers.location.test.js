const request = require('supertest');
const { createApp } = require('../../src/app');
const { Emergency, Volunteer } = require('../../src/models');
const engine = require('../../src/services/assignment/assignment.service');
const { setRoutingService, createRoutingService } = require('../../src/integrations/routing');
const { useTestDatabase } = require('../helpers/db');
const { createAccount } = require('../helpers/factories');
const {
  CENTER,
  north,
  createVolunteer,
  createOpenEmergency,
  dispatch,
} = require('../helpers/scenario');

const STALE_MS = 10 * 60 * 1000;

describe('Volunteer location and response route', () => {
  useTestDatabase();
  const app = createApp();

  beforeEach(() => {
    setRoutingService(createRoutingService({ orsApiKey: '', profile: 'foot-walking' }));
  });

  const routeOf = (auth, emergencyId) =>
    request(app)
      .get(`/api/v1/volunteers/me/emergencies/${emergencyId}/route`)
      .set('Authorization', auth);

  async function responding({ volunteerAt = north(600), emergencyAt = CENTER } = {}) {
    const responder = await createVolunteer({ location: volunteerAt });
    const { emergency } = await createOpenEmergency({ location: emergencyAt });
    await dispatch(emergency, responder.volunteer);
    return { responder, emergency };
  }

  describe('freshness', () => {
    it('reports a stale location and refreshes it on the next update', async () => {
      const { auth } = await createVolunteer({ locationAgeMs: STALE_MS });

      const before = await request(app).get('/api/v1/volunteers/me').set('Authorization', auth);
      const update = await request(app)
        .post('/api/v1/volunteers/me/location')
        .set('Authorization', auth)
        .send({ ...north(40), accuracy: 9 });

      expect(before.body.data.location.isStale).toBe(true);
      expect(update.body.data.location).toMatchObject({
        ...north(40),
        accuracy: 9,
        isStale: false,
      });
    });

    it('a stale volunteer becomes eligible again once tracking reports a fix', async () => {
      const volunteer = await createVolunteer({ locationAgeMs: STALE_MS });
      const reporter = await createAccount();

      const first = await request(app)
        .post('/api/v1/emergencies')
        .set('Authorization', reporter.auth)
        .send(CENTER);
      await engine.whenIdle();
      expect((await Emergency.findById(first.body.data.id)).status).toBe('UNASSIGNED');

      await request(app)
        .post('/api/v1/volunteers/me/location')
        .set('Authorization', volunteer.auth)
        .send(CENTER);
      await engine.retryWaitingEmergencies();
      await engine.whenIdle();

      const fresh = await Emergency.findById(first.body.data.id);
      expect(fresh.assignedVolunteerId.toString()).toBe(volunteer.volunteer.id);
    });

    it('an OFFLINE volunteer cannot keep sharing location', async () => {
      const { auth, volunteer } = await createVolunteer({
        status: 'OFFLINE',
        locationAgeMs: STALE_MS,
      });

      const res = await request(app)
        .post('/api/v1/volunteers/me/location')
        .set('Authorization', auth)
        .send(CENTER);

      expect(res.body.code).toBe('VOLUNTEER_NOT_AVAILABLE');
      const stored = await Volunteer.findById(volunteer._id);
      expect(stored.locationUpdatedAt.getTime()).toBe(volunteer.locationUpdatedAt.getTime());
    });
  });

  describe('GET /volunteers/me/emergencies/:id/route', () => {
    it('returns a straight-line estimate when road routing is not configured', async () => {
      const { responder, emergency } = await responding();

      const res = await routeOf(responder.auth, emergency.id);

      expect(res.status).toBe(200);
      expect(res.body.data).toMatchObject({
        source: 'FALLBACK',
        origin: north(600),
        destination: CENTER,
        geometry: [north(600), CENTER],
      });
      // ~600 m straight line x 1.3 detour at walking pace.
      expect(res.body.data.distanceMeters).toBeGreaterThan(700);
      expect(res.body.data.durationSeconds).toBeGreaterThan(600);
    });

    it('returns road geometry from the routing provider and caches it briefly', async () => {
      const { responder, emergency } = await responding();
      const route = jest.fn(async (origin, destination) => ({
        distanceMeters: 820,
        durationSeconds: 690,
        source: 'ROUTING',
        geometry: [origin, { latitude: 20.01, longitude: 73.793 }, destination],
      }));
      setRoutingService({ name: 'fake', matrix: jest.fn(), route });

      const first = await routeOf(responder.auth, emergency.id);
      const second = await routeOf(responder.auth, emergency.id);

      expect(first.body.data).toMatchObject({
        source: 'ROUTING',
        distanceMeters: 820,
        durationSeconds: 690,
      });
      expect(first.body.data.geometry).toHaveLength(3);
      expect(second.body.data.distanceMeters).toBe(820);
      expect(route).toHaveBeenCalledTimes(1);
    });

    it('recomputes after the volunteer moves', async () => {
      const { responder, emergency } = await responding();
      const route = jest.fn(async (origin, destination) => ({
        distanceMeters: 100,
        durationSeconds: 80,
        source: 'ROUTING',
        geometry: [origin, destination],
      }));
      setRoutingService({ name: 'fake', matrix: jest.fn(), route });

      await routeOf(responder.auth, emergency.id);
      await request(app)
        .post('/api/v1/volunteers/me/location')
        .set('Authorization', responder.auth)
        .send(north(300));
      const moved = await routeOf(responder.auth, emergency.id);

      expect(route).toHaveBeenCalledTimes(2);
      expect(moved.body.data.origin).toEqual(north(300));
    });

    it('is only available to the volunteer holding the active assignment', async () => {
      const { emergency } = await responding();
      const other = await createVolunteer({ location: north(900) });

      const res = await routeOf(other.auth, emergency.id);

      expect(res.status).toBe(404);
    });

    it('is no longer available once the assignment has ended', async () => {
      const { responder, emergency } = await responding();
      await request(app)
        .post(`/api/v1/volunteers/me/emergencies/${emergency.id}/accept`)
        .set('Authorization', responder.auth);
      await request(app)
        .post(`/api/v1/volunteers/me/emergencies/${emergency.id}/resolve`)
        .set('Authorization', responder.auth)
        .send({ resolutionNote: 'Handed to ambulance' });

      const res = await routeOf(responder.auth, emergency.id);

      expect(res.status).toBe(404);
    });

    it('explains when the emergency has no location', async () => {
      const { responder, emergency } = await responding({ emergencyAt: null });

      const res = await routeOf(responder.auth, emergency.id);

      expect(res.status).toBe(422);
      expect(res.body.code).toBe('LOCATION_UNAVAILABLE');
    });

    it('falls back to the estimate when the routing provider fails', async () => {
      const { responder, emergency } = await responding();
      const { withFallback } = require('../../src/integrations/routing');
      const failing = {
        name: 'down',
        matrix: () => Promise.reject(new Error('down')),
        route: () => Promise.reject(new Error('down')),
      };
      setRoutingService(
        withFallback(failing, createRoutingService({ orsApiKey: '', profile: 'foot-walking' })),
      );

      const res = await routeOf(responder.auth, emergency.id);

      expect(res.status).toBe(200);
      expect(res.body.data.source).toBe('FALLBACK');
    });

    it('rejects users and admins', async () => {
      const { emergency } = await responding();
      const user = await createAccount();

      const res = await routeOf(user.auth, emergency.id);

      expect(res.status).toBe(403);
    });
  });
});
