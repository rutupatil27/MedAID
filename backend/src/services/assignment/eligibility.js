const env = require('../../config/env');
const {
  ACCOUNT_STATUS,
  ROLES,
  VERIFICATION_STATUS,
  VOLUNTEER_STATUS,
} = require('../../config/constants');
const { Volunteer } = require('../../models');

/**
 * The eligibility rule (D-007) as a MongoDB filter on `volunteers`. A
 * volunteer may receive an automatic assignment only if ALL hold:
 *   - verification APPROVED
 *   - operational status ACTIVE (so not BUSY, not OFFLINE)
 *   - not reserved for another emergency (P-04)
 *   - location present and fresher than the stale threshold
 * Account suspension is checked against `users` in candidate search, and a
 * suspended volunteer is also forced OFFLINE.
 */
function eligibilityFilter(now = new Date()) {
  return {
    verificationStatus: VERIFICATION_STATUS.APPROVED,
    status: VOLUNTEER_STATUS.ACTIVE,
    currentAssignmentId: null,
    currentEmergencyId: null,
    currentLocation: { $exists: true },
    locationUpdatedAt: { $gte: new Date(now.getTime() - env.assignment.locationStaleMs) },
  };
}

/** Eligible volunteers nearest to `location` (straight line), with active accounts. */
function nearbyEligible(location, { now = new Date(), excludeIds = [] } = {}) {
  const query = eligibilityFilter(now);
  if (excludeIds.length > 0) query._id = { $nin: excludeIds };

  return Volunteer.aggregate([
    {
      $geoNear: {
        near: location,
        distanceField: 'straightLineMeters',
        maxDistance: env.assignment.searchRadiusMeters,
        spherical: true,
        query,
      },
    },
    {
      $lookup: {
        from: 'users',
        localField: 'userId',
        foreignField: '_id',
        as: 'account',
        pipeline: [{ $project: { accountStatus: 1, role: 1, name: 1 } }],
      },
    },
    { $match: { 'account.accountStatus': ACCOUNT_STATUS.ACTIVE, 'account.role': ROLES.VOLUNTEER } },
    { $limit: env.assignment.maxCandidates },
  ]);
}

/**
 * Candidates for an emergency. Volunteers who already let this emergency
 * expire or declined it are considered again only when nobody else is
 * eligible (OQ-29).
 */
async function findCandidates(emergency, { now = new Date() } = {}) {
  const excluded = emergency.excludedVolunteerIds ?? [];
  const fresh = await nearbyEligible(emergency.location, { now, excludeIds: excluded });
  if (fresh.length > 0 || excluded.length === 0) return fresh;
  return nearbyEligible(emergency.location, { now });
}

module.exports = { eligibilityFilter, nearbyEligible, findCandidates };
