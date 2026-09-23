/**
 * Creates the first ADMIN account from ADMIN_SEED_* environment variables (A-07).
 * Safe to run repeatedly: an existing account is left untouched.
 *
 *   npm run seed:admin
 */
const env = require('../src/config/env');
const logger = require('../src/utils/logger');
require('../src/models');
const { connectDatabase, disconnectDatabase } = require('../src/config/database');
const userRepository = require('../src/repositories/user.repository');
const { hashPassword } = require('../src/services/auth/password.service');
const { ROLES } = require('../src/config/constants');

async function main() {
  const { ADMIN_SEED_NAME, ADMIN_SEED_EMAIL, ADMIN_SEED_USERNAME, ADMIN_SEED_PASSWORD } =
    process.env;
  if (!ADMIN_SEED_EMAIL || !ADMIN_SEED_USERNAME || !ADMIN_SEED_PASSWORD) {
    throw new Error('Set ADMIN_SEED_EMAIL, ADMIN_SEED_USERNAME and ADMIN_SEED_PASSWORD in .env');
  }
  if (ADMIN_SEED_PASSWORD.length < 12) {
    throw new Error('ADMIN_SEED_PASSWORD must be at least 12 characters');
  }

  await connectDatabase(env.mongodbUri);
  try {
    const taken = await userRepository.findTakenFields({
      email: ADMIN_SEED_EMAIL,
      username: ADMIN_SEED_USERNAME,
    });
    if (taken.length > 0) {
      logger.warn({ taken }, 'Admin seed skipped: an account with this email/username exists');
      return;
    }
    const admin = await userRepository.create({
      name: ADMIN_SEED_NAME || 'MedAID Admin',
      email: ADMIN_SEED_EMAIL,
      username: ADMIN_SEED_USERNAME,
      passwordHash: await hashPassword(ADMIN_SEED_PASSWORD),
      role: ROLES.ADMIN,
    });
    logger.info({ id: admin.id, username: admin.username }, 'Admin account created');
  } finally {
    await disconnectDatabase();
  }
}

main().catch((err) => {
  logger.fatal({ err }, 'Admin seed failed');
  process.exit(1);
});
