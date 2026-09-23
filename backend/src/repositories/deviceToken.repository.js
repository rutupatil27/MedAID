const { DeviceToken } = require('../models');

/**
 * Registers `token` for `userId`. A token belongs to one device, so it moves
 * to the latest account that signed in on that device.
 */
function upsert({ userId, token, platform }, now = new Date()) {
  return DeviceToken.findOneAndUpdate(
    { token },
    { $set: { userId, platform, lastSeenAt: now } },
    { upsert: true, returnDocument: 'after', runValidators: true },
  );
}

async function removeForUser(userId, token) {
  const result = await DeviceToken.deleteOne({ userId, token });
  return result.deletedCount > 0;
}

function removeTokens(tokens) {
  return DeviceToken.deleteMany({ token: { $in: tokens } });
}

function findForUsers(userIds) {
  return DeviceToken.find({ userId: { $in: userIds } }).lean();
}

module.exports = { upsert, removeForUser, removeTokens, findForUsers };
