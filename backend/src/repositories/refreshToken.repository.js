const { RefreshToken } = require('../models');

function create(data) {
  return RefreshToken.create(data);
}

function findByHash(tokenHash) {
  return RefreshToken.findOne({ tokenHash });
}

/** Atomically revokes an unrevoked token for rotation. Returns null if already used. */
function markRotated(tokenHash) {
  return RefreshToken.findOneAndUpdate(
    { tokenHash, revokedAt: null },
    { $set: { revokedAt: new Date() } },
    { returnDocument: 'after' },
  );
}

function linkSuccessor(previousHash, successorHash) {
  return RefreshToken.updateOne(
    { tokenHash: previousHash },
    { $set: { replacedByHash: successorHash } },
  );
}

function revokeByHash(tokenHash) {
  return RefreshToken.updateOne(
    { tokenHash, revokedAt: null },
    { $set: { revokedAt: new Date() } },
  );
}

function revokeFamily(familyId) {
  return RefreshToken.updateMany(
    { familyId, revokedAt: null },
    { $set: { revokedAt: new Date() } },
  );
}

function revokeAllForUser(userId) {
  return RefreshToken.updateMany({ userId, revokedAt: null }, { $set: { revokedAt: new Date() } });
}

module.exports = {
  create,
  findByHash,
  markRotated,
  linkSuccessor,
  revokeByHash,
  revokeFamily,
  revokeAllForUser,
};
