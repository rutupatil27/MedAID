const AppError = require('../utils/AppError');
const { ACCOUNT_STATUS } = require('../config/constants');
const { verifyAccessToken } = require('../services/auth/token.service');
const userRepository = require('../repositories/user.repository');

/**
 * Verifies the Bearer token and loads the current account state, so suspension
 * and password changes take effect immediately (doc 22: authenticated check).
 */
async function authenticate(req, _res, next) {
  const header = req.headers.authorization ?? '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) throw AppError.unauthorized();

  const payload = verifyAccessToken(token);
  const user = await userRepository
    .findById(payload.sub)
    .select('role accountStatus mustChangePassword passwordChangedAt preferredLanguage')
    .lean();

  if (!user) throw AppError.unauthorized('Account no longer exists');
  if (user.accountStatus === ACCOUNT_STATUS.SUSPENDED) {
    throw new AppError('ACCOUNT_SUSPENDED', 'Account is suspended');
  }
  if (user.passwordChangedAt && payload.iat * 1000 < user.passwordChangedAt.getTime()) {
    throw AppError.unauthorized('Session ended after password change');
  }

  req.user = {
    id: user._id.toString(),
    role: user.role,
    mustChangePassword: Boolean(user.mustChangePassword),
    preferredLanguage: user.preferredLanguage,
  };
  next();
}

module.exports = { authenticate };
