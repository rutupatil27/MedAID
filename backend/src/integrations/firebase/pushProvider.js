const fs = require('node:fs');
const env = require('../../config/env');
const logger = require('../../utils/logger');

/**
 * PushProvider: delivers one message to a user's devices.
 *
 *   send(tokens[], { title, body, data }) -> { invalidTokens[] }
 *
 * Firebase Cloud Messaging is used when a service account is configured
 * (doc 19). Otherwise pushes are skipped: in-app notifications still work.
 */
const INVALID_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

/** @param messagingClient Test seam: a stand-in for the FCM messaging client. */
function createFcmPushProvider({ serviceAccountPath }, messagingClient = null) {
  let messaging = messagingClient;

  function client() {
    if (messaging) return messaging;
    const { initializeApp, cert, getApps } = require('firebase-admin/app');
    const { getMessaging } = require('firebase-admin/messaging');
    const credentials = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    const app = getApps()[0] ?? initializeApp({ credential: cert(credentials) });
    messaging = getMessaging(app);
    return messaging;
  }

  return {
    name: 'fcm',

    async send(tokens, { title, body, data }) {
      const response = await client().sendEachForMulticast({
        tokens,
        // Deliberately no top-level `notification` block. That tells Android to
        // draw the alert itself, on its default channel, and to skip the app
        // entirely when it has been killed — which costs the looping ring and
        // the Accept/Decline buttons. A data-only message wakes the app's
        // background isolate instead, so the alert is always the app's own
        // (doc 19). The text travels in `data` for it to render.
        data: { ...data, title, body },
        // Required for a data-only message to wake a dozing or killed app.
        android: { priority: 'high' },
        // iOS cannot draw a notification from a data-only message, so its
        // alert text stays in the APNs payload.
        apns: {
          headers: { 'apns-priority': '10' },
          payload: { aps: { alert: { title, body }, sound: 'default' } },
        },
      });
      const invalidTokens = response.responses
        .map((result, i) =>
          !result.success && INVALID_TOKEN_CODES.has(result.error?.code) ? tokens[i] : null,
        )
        .filter(Boolean);
      return { invalidTokens };
    },
  };
}

function createNoopPushProvider() {
  return {
    name: 'none',
    async send(tokens, { data }) {
      logger.debug(
        { type: data?.type, devices: tokens.length },
        'Push skipped (FCM not configured)',
      );
      return { invalidTokens: [] };
    },
  };
}

function createPushProvider(config = env.fcm) {
  if (!config.serviceAccountPath) return createNoopPushProvider();
  return createFcmPushProvider(config);
}

let provider = null;

function getPushProvider() {
  provider ??= createPushProvider();
  return provider;
}

/** Test seam: replace the push provider. */
function setPushProvider(replacement) {
  provider = replacement;
}

module.exports = { getPushProvider, setPushProvider, createPushProvider, createFcmPushProvider };
