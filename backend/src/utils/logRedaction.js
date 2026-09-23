/**
 * Fields that must never reach the logs (doc 22). Kept separate from the
 * logger so the policy can be asserted in tests.
 */
const REDACT = Object.freeze({
  paths: [
    'req.headers.authorization',
    'req.headers.cookie',
    'password',
    '*.password',
    '*.newPassword',
    '*.currentPassword',
    '*.passwordHash',
    '*.token',
    '*.accessToken',
    '*.refreshToken',
    '*.fcmToken',
  ],
  censor: '[REDACTED]',
});

module.exports = { REDACT };
