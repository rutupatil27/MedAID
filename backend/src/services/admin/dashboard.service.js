const {
  EMERGENCY_STATUS: S,
  OPEN_EMERGENCY_STATUSES,
  VERIFICATION_STATUS,
  VOLUNTEER_STATUS,
} = require('../../config/constants');
const { Emergency, User, Volunteer } = require('../../models');
const campRepository = require('../../repositories/medicalCamp.repository');
const emergencyAdminService = require('./emergencyAdmin.service');

const toCounts = (rows, keys) =>
  Object.fromEntries(keys.map((key) => [key, rows.find((r) => r._id === key)?.count ?? 0]));

const countBy = (Model, field, match = {}) =>
  Model.aggregate([{ $match: match }, { $group: { _id: `$${field}`, count: { $sum: 1 } } }]);

/** Operational snapshot for the admin dashboard (doc 27, admin #2). */
async function getDashboard() {
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  const [emergencyRows, verificationRows, statusRows, users, todayCount, activeCamps, open] =
    await Promise.all([
      countBy(Emergency, 'status', { isOpen: true }),
      countBy(Volunteer, 'verificationStatus'),
      countBy(Volunteer, 'status'),
      countBy(User, 'role'),
      Emergency.countDocuments({ createdAt: { $gte: startOfDay } }),
      campRepository.countCurrentlyValid(),
      emergencyAdminService.list({ open: true, page: 1, limit: 5 }),
    ]);

  const openByStatus = toCounts(emergencyRows, OPEN_EMERGENCY_STATUSES);
  return {
    emergencies: {
      open: Object.values(openByStatus).reduce((a, b) => a + b, 0),
      unassigned: openByStatus[S.UNASSIGNED],
      awaitingAcceptance: openByStatus[S.ASSIGNED],
      inProgress: openByStatus[S.ACCEPTED] + openByStatus[S.IN_PROGRESS],
      today: todayCount,
      openByStatus,
    },
    volunteers: {
      byVerification: toCounts(verificationRows, Object.values(VERIFICATION_STATUS)),
      byStatus: toCounts(statusRows, Object.values(VOLUNTEER_STATUS)),
      pendingVerification:
        verificationRows.find((r) => r._id === VERIFICATION_STATUS.PENDING)?.count ?? 0,
    },
    users: toCounts(users, ['USER', 'VOLUNTEER', 'ADMIN']),
    camps: { activeNow: activeCamps },
    recentOpenEmergencies: open.items,
  };
}

module.exports = { getDashboard };
