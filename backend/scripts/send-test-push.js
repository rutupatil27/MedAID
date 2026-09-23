/**
 * Sends a test push to one user's registered devices, so a Firebase setup can
 * be checked without staging a whole emergency.
 *
 *   node scripts/send-test-push.js volunteer@example.com
 *
 * Reports what happened at each step: whether FCM is configured, whether the
 * account has any devices registered, and what FCM said about each token.
 */
const env = require('../src/config/env');
const logger = require('../src/utils/logger');
require('../src/models');
const { connectDatabase, disconnectDatabase } = require('../src/config/database');
const userRepository = require('../src/repositories/user.repository');
const deviceTokenRepository = require('../src/repositories/deviceToken.repository');
const { getPushProvider } = require('../src/integrations/firebase/pushProvider');

async function main() {
  const identifier = process.argv[2];
  if (!identifier) {
    throw new Error('Usage: node scripts/send-test-push.js <email-or-username>');
  }

  const provider = getPushProvider();
  if (provider.name !== 'fcm') {
    throw new Error(
      'Push is not configured: set FCM_SERVICE_ACCOUNT_PATH in .env to the Firebase ' +
        'service-account JSON, then run this again.',
    );
  }

  await connectDatabase(env.mongodbUri);
  try {
    const user = await userRepository.findByIdentifier(identifier);
    if (!user) throw new Error(`No account found for "${identifier}"`);

    const devices = await deviceTokenRepository.findForUsers([user._id]);
    if (devices.length === 0) {
      throw new Error(
        `"${identifier}" has no registered devices. Sign in on the phone with a build made ` +
          'with ENABLE_PUSH, which registers the device on login.',
      );
    }

    const { invalidTokens } = await provider.send(
      devices.map((device) => device.token),
      {
        title: 'MedAID test',
        body: 'Push is working. This is not a real emergency.',
        // Not ASSIGNMENT_NEW: the app must not raise an emergency alert or ring
        // for a test message.
        data: { type: 'TEST' },
      },
    );

    logger.info(
      { devices: devices.length, rejected: invalidTokens.length },
      'Test push sent to FCM',
    );
    if (invalidTokens.length > 0) {
      logger.warn(
        'FCM rejected some tokens as unknown. They are usually stale: sign out and in again ' +
          'on the phone to register a fresh one.',
      );
    }
  } finally {
    await disconnectDatabase();
  }
}

main().catch((err) => {
  logger.error({ err: err.message }, 'Test push failed');
  process.exit(1);
});
