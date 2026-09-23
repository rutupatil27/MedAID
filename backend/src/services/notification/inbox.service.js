const AppError = require('../../utils/AppError');
const { ROLES, VERIFICATION_STATUS } = require('../../config/constants');
const notificationRepository = require('../../repositories/notification.repository');
const deviceTokenRepository = require('../../repositories/deviceToken.repository');
const volunteerRepository = require('../../repositories/volunteer.repository');
const userRepository = require('../../repositories/user.repository');
const notificationService = require('./notification.service');

/** Notification center and device registration for every role (P-16). */
function toView(notification) {
  return {
    id: notification.id,
    type: notification.type,
    title: notification.title,
    body: notification.body,
    data: Object.fromEntries(notification.data ?? []),
    isRead: notification.readAt != null,
    readAt: notification.readAt,
    createdAt: notification.createdAt,
  };
}

async function list(userId, { unreadOnly, page, limit }) {
  const { items, total, unreadCount } = await notificationRepository.listForUser(userId, {
    unreadOnly,
    page,
    limit,
  });
  return { items: items.map(toView), page, limit, total, unreadCount };
}

async function unreadCount(userId) {
  return { unreadCount: await notificationRepository.countUnread(userId) };
}

async function markRead(userId, id) {
  const updated = await notificationRepository.markRead(userId, id);
  // Another account's notification looks exactly like a missing one.
  if (!updated) throw AppError.notFound('Notification');
  return toView(updated);
}

async function markAllRead(userId) {
  return { updated: await notificationRepository.markAllRead(userId) };
}

async function registerDevice(userId, { token, platform }) {
  await deviceTokenRepository.upsert({ userId, token, platform });
  return { registered: true };
}

async function unregisterDevice(userId, token) {
  return { removed: await deviceTokenRepository.removeForUser(userId, token) };
}

/** Admin notice to every approved volunteer with an active account (doc 19). */
async function sendVolunteerNotice(message) {
  const userIds = await volunteerRepository.findUserIdsByVerification(VERIFICATION_STATUS.APPROVED);
  const recipients = await userRepository.filterActive(userIds, ROLES.VOLUNTEER);
  const sent = await notificationService.notify({
    type: notificationService.EVENTS.ADMIN_NOTICE,
    recipients,
    message,
  });
  return { recipients: sent.length };
}

module.exports = {
  toView,
  list,
  unreadCount,
  markRead,
  markAllRead,
  registerDevice,
  unregisterDevice,
  sendVolunteerNotice,
};
