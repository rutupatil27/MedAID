const { Notification } = require('../models');

function insertMany(docs) {
  return Notification.insertMany(docs);
}

async function listForUser(userId, { unreadOnly, page, limit }) {
  const filter = { recipientUserId: userId };
  if (unreadOnly) filter.readAt = null;
  const [items, total, unreadCount] = await Promise.all([
    Notification.find(filter)
      .sort({ createdAt: -1, _id: -1 })
      .skip((page - 1) * limit)
      .limit(limit),
    Notification.countDocuments(filter),
    countUnread(userId),
  ]);
  return { items, total, unreadCount };
}

function countUnread(userId) {
  return Notification.countDocuments({ recipientUserId: userId, readAt: null });
}

/** Marks one of the user's notifications read; null when it is not theirs. */
function markRead(userId, id, now = new Date()) {
  return Notification.findOneAndUpdate(
    { _id: id, recipientUserId: userId },
    [{ $set: { readAt: { $ifNull: ['$readAt', now] } } }],
    { returnDocument: 'after', updatePipeline: true },
  );
}

async function markAllRead(userId, now = new Date()) {
  const result = await Notification.updateMany(
    { recipientUserId: userId, readAt: null },
    { $set: { readAt: now } },
  );
  return result.modifiedCount;
}

module.exports = { insertMany, listForUser, countUnread, markRead, markAllRead };
