/**
 * Resets the seeded admin's password to the current ADMIN_SEED_PASSWORD.
 *
 *   node scripts/reset-admin-password.js
 *
 * `seed:admin` deliberately leaves an existing account untouched, so it cannot
 * be used to change a password that was set with a weaker value — which is the
 * usual case once an environment has been live for a while.
 *
 * Every other session is signed out, as a password change through the API does.
 * Pass --verify <base-url> to confirm the new password logs in against a
 * deployed API afterwards; the password is read from the environment and is
 * never printed or passed on the command line.
 */
const env = require('../src/config/env');
const logger = require('../src/utils/logger');
require('../src/models');
const { connectDatabase, disconnectDatabase } = require('../src/config/database');
const userRepository = require('../src/repositories/user.repository');
const tokenService = require('../src/services/auth/token.service');
const { hashPassword } = require('../src/services/auth/password.service');
const { ROLES } = require('../src/config/constants');

async function verifyLogin(baseUrl, identifier, password) {
  const url = `${baseUrl.replace(/\/$/, '')}/auth/login`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier, password }),
  });
  const body = await response.json().catch(() => ({}));
  return { ok: response.ok, status: response.status, code: body.code, role: body.data?.user?.role };
}

async function main() {
  const { ADMIN_SEED_EMAIL, ADMIN_SEED_USERNAME, ADMIN_SEED_PASSWORD } = process.env;
  const identifier = ADMIN_SEED_EMAIL || ADMIN_SEED_USERNAME;
  if (!identifier || !ADMIN_SEED_PASSWORD) {
    throw new Error(
      'Set ADMIN_SEED_EMAIL (or ADMIN_SEED_USERNAME) and ADMIN_SEED_PASSWORD in .env',
    );
  }
  if (ADMIN_SEED_PASSWORD.length < 12) {
    throw new Error('ADMIN_SEED_PASSWORD must be at least 12 characters');
  }

  const verifyIndex = process.argv.indexOf('--verify');
  const verifyBaseUrl = verifyIndex === -1 ? null : process.argv[verifyIndex + 1];
  if (verifyIndex !== -1 && !verifyBaseUrl) {
    throw new Error('--verify needs a base URL, e.g. --verify https://host/api/v1');
  }

  await connectDatabase(env.mongodbUri);
  try {
    const user = await userRepository.findByIdentifier(identifier);
    if (!user) throw new Error(`No account found for "${identifier}"`);
    if (user.role !== ROLES.ADMIN) {
      throw new Error(`"${identifier}" is a ${user.role}, not an ADMIN — refusing to touch it`);
    }

    await userRepository.updateById(user._id, {
      $set: {
        passwordHash: await hashPassword(ADMIN_SEED_PASSWORD),
        // Backdated a second, as changePassword does, so tokens issued in the
        // same second are not invalidated by their own change.
        passwordChangedAt: new Date(Date.now() - 1000),
        mustChangePassword: false,
      },
    });
    await tokenService.revokeAllForUser(user._id);
    logger.info({ username: user.username }, 'Admin password reset; other sessions signed out');

    if (verifyBaseUrl) {
      const result = await verifyLogin(verifyBaseUrl, identifier, ADMIN_SEED_PASSWORD);
      if (result.ok && result.role === ROLES.ADMIN) {
        logger.info({ url: verifyBaseUrl }, 'Login verified against the deployed API');
      } else {
        logger.error(result, 'Login against the deployed API FAILED');
        process.exitCode = 1;
      }
    }
  } finally {
    await disconnectDatabase();
  }
}

main().catch((err) => {
  logger.error({ err: err.message }, 'Admin password reset failed');
  process.exit(1);
});
