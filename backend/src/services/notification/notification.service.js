const logger = require('../../utils/logger');
const userRepository = require('../../repositories/user.repository');
const notificationRepository = require('../../repositories/notification.repository');
const deviceTokenRepository = require('../../repositories/deviceToken.repository');
const { getPushProvider } = require('../../integrations/firebase/pushProvider');
const { render } = require('./templates');

/**
 * Notification delivery (doc 19). Business services describe WHAT happened;
 * this service stores an in-app record per recipient, localized to their
 * language, and pushes it to their devices.
 *
 * Notifications never break the business flow: failures are logged, not
 * thrown. Pushes are sent in the background (see `whenIdle`).
 */
const EVENTS = Object.freeze({
  EMERGENCY_CREATED: 'EMERGENCY_CREATED',
  EMERGENCY_ASSIGNED: 'EMERGENCY_ASSIGNED',
  EMERGENCY_ACCEPTED: 'EMERGENCY_ACCEPTED',
  EMERGENCY_IN_PROGRESS: 'EMERGENCY_IN_PROGRESS',
  EMERGENCY_RESOLVED: 'EMERGENCY_RESOLVED',
  EMERGENCY_CANCELLED: 'EMERGENCY_CANCELLED',
  EMERGENCY_REASSIGNING: 'EMERGENCY_REASSIGNING',
  EMERGENCY_UNASSIGNED: 'EMERGENCY_UNASSIGNED',
  EMERGENCY_ESCALATED: 'EMERGENCY_ESCALATED',
  ASSIGNMENT_NEW: 'ASSIGNMENT_NEW',
  ASSIGNMENT_EXPIRING: 'ASSIGNMENT_EXPIRING',
  ASSIGNMENT_EXPIRED: 'ASSIGNMENT_EXPIRED',
  ASSIGNMENT_CANCELLED: 'ASSIGNMENT_CANCELLED',
  VERIFICATION_SUBMITTED: 'VERIFICATION_SUBMITTED',
  VERIFICATION_APPROVED: 'VERIFICATION_APPROVED',
  VERIFICATION_REJECTED: 'VERIFICATION_REJECTED',
  ACCOUNT_SUSPENDED: 'ACCOUNT_SUSPENDED',
  ADMIN_NOTICE: 'ADMIN_NOTICE',
});

/** Payloads carry IDs and reason codes only, never personal data (doc 19). */
const ALLOWED_DATA_KEYS = Object.freeze(['emergencyId', 'assignmentId', 'volunteerId', 'reason']);

function sanitizeData(data = {}) {
  const clean = {};
  for (const key of ALLOWED_DATA_KEYS) {
    if (data[key] != null) clean[key] = String(data[key]);
  }
  return clean;
}

// ---- Background push tracking -----------------------------------------------

const inflight = new Set();

function track(promise) {
  const tracked = promise
    .catch((err) => logger.error({ err }, 'Push delivery failed'))
    .finally(() => inflight.delete(tracked));
  inflight.add(tracked);
}

/** Resolves once every queued push has been attempted (tests, shutdown). */
async function whenIdle() {
  while (inflight.size > 0) await Promise.allSettled([...inflight]);
}

async function push(notifications) {
  const userIds = [...new Set(notifications.map((n) => n.recipientUserId.toString()))];
  const devices = await deviceTokenRepository.findForUsers(userIds);
  if (devices.length === 0) return;

  const provider = getPushProvider();
  const invalid = [];
  for (const notification of notifications) {
    const tokens = devices
      .filter((d) => d.userId.toString() === notification.recipientUserId.toString())
      .map((d) => d.token);
    if (tokens.length === 0) continue;
    const { invalidTokens } = await provider.send(tokens, {
      title: notification.title,
      body: notification.body,
      data: {
        ...Object.fromEntries(notification.data),
        type: notification.type,
        notificationId: notification.id,
      },
    });
    invalid.push(...invalidTokens);
  }
  if (invalid.length > 0) await deviceTokenRepository.removeTokens(invalid);
}

// ---- Delivery ---------------------------------------------------------------

async function deliver(recipients, { type, data, message }) {
  if (recipients.length === 0) return [];
  const payload = sanitizeData(data);
  const created = await notificationRepository.insertMany(
    recipients.map((user) => ({
      recipientUserId: user._id,
      type,
      ...render(type, user.role, user.preferredLanguage, { message }),
      data: payload,
    })),
  );
  track(push(created));
  return created;
}

/**
 * @param {{ type: string, recipients: Array<string|import('mongoose').Types.ObjectId>,
 *   data?: Record<string, string>, message?: string }} event
 *   `message` replaces the template body (admin notices only).
 */
async function notify({ type, recipients, data, message }) {
  try {
    const ids = [...new Set(recipients.filter(Boolean).map(String))];
    const users = ids.length > 0 ? await userRepository.findRecipients(ids) : [];
    return await deliver(users, { type, data, message });
  } catch (err) {
    logger.error({ err, type }, 'Notification failed');
    return [];
  }
}

/** Sends an event to every active ADMIN account. */
async function notifyAdmins({ type, data }) {
  try {
    return await deliver(await userRepository.findAdmins(), { type, data });
  } catch (err) {
    logger.error({ err, type }, 'Admin notification failed');
    return [];
  }
}

module.exports = { notify, notifyAdmins, whenIdle, sanitizeData, EVENTS, ALLOWED_DATA_KEYS };
