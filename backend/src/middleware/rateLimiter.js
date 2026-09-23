const { rateLimit } = require('express-rate-limit');
const env = require('../config/env');
const { sendError } = require('../utils/apiResponse');

function createRateLimiter({ windowMs, limit }) {
  return rateLimit({
    windowMs,
    limit,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    handler: (_req, res) =>
      sendError(res, {
        status: 429,
        code: 'RATE_LIMITED',
        message: 'Too many requests, please try again later',
      }),
  });
}

/** General API limiter. */
const apiLimiter = createRateLimiter({
  windowMs: env.rateLimit.windowMs,
  limit: env.rateLimit.max,
});

/** Stricter limiter for credential endpoints (brute-force protection). */
const authLimiter = createRateLimiter({
  windowMs: env.rateLimit.windowMs,
  limit: env.rateLimit.authMax,
});

module.exports = { createRateLimiter, apiLimiter, authLimiter };
