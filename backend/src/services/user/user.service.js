const AppError = require('../../utils/AppError');
const { ACCOUNT_STATUS, ROLES } = require('../../config/constants');
const { Volunteer } = require('../../models');
const userRepository = require('../../repositories/user.repository');
const tokenService = require('../auth/token.service');

async function getMe(userId) {
  const user = await userRepository.findById(userId);
  if (!user) throw AppError.notFound('User');
  return user;
}

/** Medical profile applies to USER accounts only (OQ-16). */
async function updateMe(userId, role, changes) {
  const set = {};
  for (const field of ['name', 'phone', 'preferredLanguage']) {
    if (changes[field] !== undefined) set[field] = changes[field];
  }

  if (changes.medicalProfile !== undefined) {
    if (role !== ROLES.USER) {
      throw AppError.validation([
        { field: 'body.medicalProfile', message: 'Only users have a medical profile' },
      ]);
    }
    for (const [key, value] of Object.entries(changes.medicalProfile)) {
      set[`medicalProfile.${key}`] = value;
    }
  }

  const user = await userRepository.updateById(userId, { $set: set });
  if (!user) throw AppError.notFound('User');
  return user;
}

async function listUsers({ role, accountStatus, search, page, limit }) {
  const { items, total } = await userRepository.list({ role, accountStatus, search, page, limit });
  return { items, page, limit, total };
}

/**
 * Suspends or reactivates any account (OQ-11). Volunteer accounts go through
 * the volunteer flow so their emergencies are handed back safely. Admins
 * cannot suspend themselves.
 */
async function setAccountStatus(userId, { accountStatus, adminUserId }) {
  if (userId.toString() === adminUserId.toString()) {
    throw AppError.forbidden('You cannot change your own account status');
  }
  const user = await userRepository.findById(userId);
  if (!user) throw AppError.notFound('User');

  if (user.role === ROLES.VOLUNTEER) {
    const volunteer = await Volunteer.findOne({ userId: user._id });
    if (volunteer) {
      // Required lazily to avoid a circular import with the admin services.
      const volunteerAdminService = require('../admin/volunteerAdmin.service');
      await volunteerAdminService.setAccountStatus(volunteer._id, { accountStatus, adminUserId });
      return userRepository.findById(userId);
    }
  }

  const updated = await userRepository.updateById(
    userId,
    accountStatus === ACCOUNT_STATUS.SUSPENDED
      ? { $set: { accountStatus, suspendedAt: new Date(), suspendedBy: adminUserId } }
      : { $set: { accountStatus }, $unset: { suspendedAt: '', suspendedBy: '' } },
  );
  if (accountStatus === ACCOUNT_STATUS.SUSPENDED) await tokenService.revokeAllForUser(userId);
  return updated;
}

module.exports = { getMe, updateMe, listUsers, setAccountStatus };
