const { APP_TIMEZONE, EMERGENCY_STATUS: S } = require('../../config/constants');
const { Emergency } = require('../../models');

const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Basic analytics (OQ-26): volumes, outcomes, response times and how often
 * alerts needed more than one dispatch attempt.
 */
async function summary({ from, to }) {
  const end = to ?? new Date();
  const start = from ?? new Date(end.getTime() - 7 * DAY_MS);
  const match = { createdAt: { $gte: start, $lte: end } };

  const [totals] = await Emergency.aggregate([
    { $match: match },
    {
      $group: {
        _id: null,
        total: { $sum: 1 },
        resolved: { $sum: { $cond: [{ $eq: ['$status', S.RESOLVED] }, 1, 0] } },
        cancelled: { $sum: { $cond: [{ $eq: ['$status', S.CANCELLED] }, 1, 0] } },
        open: { $sum: { $cond: ['$isOpen', 1, 0] } },
        reassigned: { $sum: { $cond: [{ $gt: ['$attemptCount', 1] }, 1, 0] } },
        everUnassigned: { $sum: { $cond: [{ $ifNull: ['$unassignedAt', false] }, 1, 0] } },
        avgAcceptMs: {
          $avg: { $cond: ['$acceptedAt', { $subtract: ['$acceptedAt', '$createdAt'] }, null] },
        },
        avgResolveMs: {
          $avg: { $cond: ['$resolvedAt', { $subtract: ['$resolvedAt', '$createdAt'] }, null] },
        },
      },
    },
  ]);

  const perDay = await Emergency.aggregate([
    { $match: match },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt', timezone: APP_TIMEZONE } },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  const t = totals ?? {};
  const seconds = (ms) => (ms == null ? null : Math.round(ms / 1000));
  return {
    range: { from: start, to: end },
    emergencies: {
      total: t.total ?? 0,
      resolved: t.resolved ?? 0,
      cancelled: t.cancelled ?? 0,
      open: t.open ?? 0,
      reassigned: t.reassigned ?? 0,
      everUnassigned: t.everUnassigned ?? 0,
      reassignmentRate: t.total ? Number((t.reassigned / t.total).toFixed(3)) : 0,
      avgTimeToAcceptSeconds: seconds(t.avgAcceptMs),
      avgTimeToResolveSeconds: seconds(t.avgResolveMs),
    },
    perDay: perDay.map((d) => ({ date: d._id, count: d.count })),
  };
}

module.exports = { summary };
