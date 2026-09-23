const crypto = require('node:crypto');
const jwt = require('jsonwebtoken');
const env = require('../../config/env');
const AppError = require('../../utils/AppError');
const refreshTokenRepository = require('../../repositories/refreshToken.repository');

const JWT_OPTIONS = { algorithm: 'HS256', issuer: 'medaid-api', audience: 'medaid-app' };

/** A client that lost a rotation response may retry within this window (P-11). */
const ROTATION_GRACE_MS = 20 * 1000;

const sha256 = (value) => crypto.createHash('sha256').update(value).digest('hex');

function signAccessToken(user) {
  return jwt.sign({ role: user.role }, env.auth.accessSecret, {
    ...JWT_OPTIONS,
    subject: user._id.toString(),
    expiresIn: env.auth.accessExpiresIn,
  });
}

/** @returns {{ sub: string, role: string, iat: number, exp: number }} */
function verifyAccessToken(token) {
  try {
    return jwt.verify(token, env.auth.accessSecret, {
      algorithms: [JWT_OPTIONS.algorithm],
      issuer: JWT_OPTIONS.issuer,
      audience: JWT_OPTIONS.audience,
    });
  } catch (_err) {
    throw AppError.unauthorized('Invalid or expired access token');
  }
}

/**
 * Issues an access token and a new refresh token. When `previousHash` is
 * given, the new refresh token is recorded as its successor.
 */
async function issueTokens(user, { familyId = crypto.randomUUID(), previousHash, userAgent } = {}) {
  const accessToken = signAccessToken(user);
  const { exp } = jwt.decode(accessToken);

  const refreshToken = crypto.randomBytes(48).toString('base64url');
  const tokenHash = sha256(refreshToken);
  await refreshTokenRepository.create({
    userId: user._id,
    tokenHash,
    familyId,
    userAgent: userAgent?.slice(0, 300),
    expiresAt: new Date(Date.now() + env.auth.refreshTokenTtlDays * 24 * 60 * 60 * 1000),
  });
  if (previousHash) await refreshTokenRepository.linkSuccessor(previousHash, tokenHash);

  return {
    accessToken,
    refreshToken,
    accessTokenExpiresAt: new Date(exp * 1000).toISOString(),
  };
}

/**
 * Consumes a refresh token for rotation. Reusing a rotated token outside the
 * grace window is treated as theft and revokes the whole family.
 * @returns {Promise<{ userId: string, familyId: string, previousHash: string }>}
 */
async function consumeRefreshToken(rawToken) {
  const tokenHash = sha256(rawToken);
  const stored = await refreshTokenRepository.findByHash(tokenHash);
  if (!stored || stored.expiresAt <= new Date()) {
    throw AppError.unauthorized('Invalid refresh token');
  }

  const result = {
    userId: stored.userId.toString(),
    familyId: stored.familyId,
    previousHash: tokenHash,
  };

  if (stored.revokedAt) {
    const withinGrace =
      stored.replacedByHash && Date.now() - stored.revokedAt.getTime() < ROTATION_GRACE_MS;
    if (!withinGrace) {
      await refreshTokenRepository.revokeFamily(stored.familyId);
      throw AppError.unauthorized('Refresh token reuse detected');
    }
    // The client never received the successor: revoke it and continue the family.
    await refreshTokenRepository.revokeByHash(stored.replacedByHash);
    return result;
  }

  const rotated = await refreshTokenRepository.markRotated(tokenHash);
  if (!rotated) throw AppError.unauthorized('Refresh token already used');
  return result;
}

async function revokeRefreshTokenFamily(rawToken) {
  const stored = await refreshTokenRepository.findByHash(sha256(rawToken));
  if (stored) await refreshTokenRepository.revokeFamily(stored.familyId);
}

function revokeAllForUser(userId) {
  return refreshTokenRepository.revokeAllForUser(userId);
}

module.exports = {
  signAccessToken,
  verifyAccessToken,
  issueTokens,
  consumeRefreshToken,
  revokeRefreshTokenFamily,
  revokeAllForUser,
};
