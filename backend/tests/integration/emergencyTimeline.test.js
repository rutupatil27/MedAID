const request = require('supertest');
const { createApp } = require('../../src/app');
const { Emergency } = require('../../src/models');
const { useTestDatabase } = require('../helpers/db');
const { createOpenEmergency } = require('../helpers/scenario');
const emergencyRepository = require('../../src/repositories/emergency.repository');
const { EMERGENCY_STATUS: S } = require('../../src/config/constants');

const historyOf = async (emergency) =>
  (await Emergency.findById(emergency._id)).statusHistory.map((entry) => entry.status);

describe('Emergency timeline', () => {
  useTestDatabase();
  const app = createApp();

  describe('history entries', () => {
    it('records a transition that changes the status', async () => {
      const { emergency } = await createOpenEmergency({ status: S.CREATED });

      await emergencyRepository.transition(emergency._id, {
        from: [S.CREATED, S.ASSIGNING],
        to: S.ASSIGNING,
      });

      expect(await historyOf(emergency)).toEqual([S.CREATED, S.ASSIGNING]);
    });

    it('records nothing when the emergency already has the status it moves to', async () => {
      const { emergency } = await createOpenEmergency({ status: S.ASSIGNING });

      // Admin reassignment allows ASSIGNING in both `from` and `to`, so
      // pressing it on an emergency that is already being assigned changes
      // nothing. A second identical row would read as a bug in the timeline.
      const updated = await emergencyRepository.transition(emergency._id, {
        from: [S.CREATED, S.ASSIGNING, S.ASSIGNED],
        to: S.ASSIGNING,
        set: { assignedVolunteerId: null },
      });

      expect(updated).not.toBeNull();
      expect(await historyOf(emergency)).toEqual([S.ASSIGNING]);
    });

    it('still applies the other changes of a transition that writes no history', async () => {
      const { emergency } = await createOpenEmergency({ status: S.ASSIGNING });
      await Emergency.updateOne(
        { _id: emergency._id },
        { $set: { assignmentLockUntil: new Date() } },
      );

      await emergencyRepository.transition(emergency._id, {
        from: [S.ASSIGNING],
        to: S.ASSIGNING,
        set: { assignmentLockUntil: null },
      });

      expect((await Emergency.findById(emergency._id)).assignmentLockUntil).toBeNull();
    });

    it('leaves the emergency alone when the precondition does not hold', async () => {
      const { emergency } = await createOpenEmergency({ status: S.RESOLVED });

      const updated = await emergencyRepository.transition(emergency._id, {
        from: [S.CREATED, S.ASSIGNING],
        to: S.ASSIGNING,
      });

      expect(updated).toBeNull();
      expect(await historyOf(emergency)).toEqual([S.RESOLVED]);
    });
  });

  describe('what the app is told', () => {
    it('carries the reason, so repeated statuses can be told apart', async () => {
      const { reporter, emergency } = await createOpenEmergency({ status: S.CREATED });
      await emergencyRepository.transition(emergency._id, {
        from: [S.CREATED],
        to: S.UNASSIGNED,
        note: 'NO_ELIGIBLE_VOLUNTEER',
      });

      const res = await request(app)
        .get(`/api/v1/emergencies/${emergency._id}`)
        .set('Authorization', reporter.auth);

      expect(res.body.data.timeline).toEqual([
        { status: S.CREATED, at: expect.any(String), reason: null },
        { status: S.UNASSIGNED, at: expect.any(String), reason: 'NO_ELIGIBLE_VOLUNTEER' },
      ]);
    });

    it('never repeats free text written by someone else', async () => {
      const { reporter, emergency } = await createOpenEmergency({ status: S.CREATED });
      // A user's cancellation reason is theirs; it is not timeline material for
      // every volunteer and admin who later opens the alert (doc 19).
      await emergencyRepository.transition(emergency._id, {
        from: [S.CREATED],
        to: S.CANCELLED,
        note: 'changed my mind, my brother is diabetic and already took insulin',
      });

      const res = await request(app)
        .get(`/api/v1/emergencies/${emergency._id}`)
        .set('Authorization', reporter.auth);

      const cancelled = res.body.data.timeline.at(-1);
      expect(cancelled.status).toBe(S.CANCELLED);
      expect(cancelled.reason).toBeNull();
      expect(JSON.stringify(res.body)).not.toContain('diabetic');
    });
  });
});
