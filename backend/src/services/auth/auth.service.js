const AppError = require('../../utils/AppError');
const { ROLES, ACCOUNT_STATUS } = require('../../config/constants');
const userRepository = require('../../repositories/user.repository');
const { hashPassword, verifyPassword } = require('./password.service');
const tokenService = require('./token.service');

function assertAccountUsable(user) {
  if (user.accountStatus === ACCOUNT_STATUS.SUSPENDED) {
    throw new AppError('ACCOUNT_SUSPENDED', 'Account is suspended');
  }
}

/** Self-registration creates USER accounts only (D-016). */
async function register(input, { userAgent } = {}) {
  const taken = await userRepository.findTakenFields(input);
  if (taken.length > 0) {
    throw new AppError('CONFLICT', 'Account already exists', {
      errors: taken.map((field) => ({ field: `body.${field}`, message: 'Already in use' })),
    });
  }

  const user = await userRepository.create({
    name: input.name,
    email: input.email,
    username: input.username,
    phone: input.phone,
    preferredLanguage: input.preferredLanguage,
    passwordHash: await hashPassword(input.password),
    role: ROLES.USER,
    lastLoginAt: new Date(),
  });

  const tokens = await tokenService.issueTokens(user, { userAgent });
  return { user, ...tokens };
}

async function login({ identifier, password }, { userAgent } = {}) {
  const user = await userRepository.findByIdentifier(identifier, { withPassword: true });
  const valid = await verifyPassword(password, user?.passwordHash);
  if (!user || !valid) throw new AppError('AUTH_INVALID', 'Invalid credentials');

  // Checked after the password so suspension status does not leak to guessers.
  assertAccountUsable(user);

  const updated = await userRepository.updateById(user._id, { $set: { lastLoginAt: new Date() } });
  const tokens = await tokenService.issueTokens(updated, { userAgent });
  return { user: updated, ...tokens };
}

async function refresh(refreshToken, { userAgent } = {}) {
  const { userId, familyId, previousHash } = await tokenService.consumeRefreshToken(refreshToken);

  const user = await userRepository.findById(userId);
  if (!user) throw AppError.unauthorized('Account no longer exists');
  if (user.accountStatus === ACCOUNT_STATUS.SUSPENDED) {
    await tokenService.revokeAllForUser(user._id);
    assertAccountUsable(user);
  }

  const tokens = await tokenService.issueTokens(user, { familyId, previousHash, userAgent });
  return { user, ...tokens };
}

async function logout(refreshToken) {
  if (refreshToken) await tokenService.revokeRefreshTokenFamily(refreshToken);
}

/** Changing the password signs out every other session. */
async function changePassword(userId, { currentPassword, newPassword }, { userAgent } = {}) {
  const user = await userRepository.findById(userId, { withPassword: true });
  if (!user) throw AppError.unauthorized();

  if (!(await verifyPassword(currentPassword, user.passwordHash))) {
    throw new AppError('AUTH_INVALID', 'Current password is incorrect', {
      errors: [{ field: 'body.currentPassword', message: 'Incorrect password' }],
    });
  }

  // One-second backdate so tokens issued in the same second stay valid.
  const updated = await userRepository.updateById(user._id, {
    $set: {
      passwordHash: await hashPassword(newPassword),
      passwordChangedAt: new Date(Date.now() - 1000),
      mustChangePassword: false,
    },
  });
  await tokenService.revokeAllForUser(user._id);

  const tokens = await tokenService.issueTokens(updated, { userAgent });
  return { user: updated, ...tokens };
}

module.exports = { register, login, refresh, logout, changePassword };
