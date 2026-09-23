const pino = require('pino');
const env = require('../config/env');
const { REDACT } = require('./logRedaction');

/** Structured logger. Secrets and credentials are always redacted (doc 22). */
const logger = pino({ level: env.logLevel, redact: REDACT });

module.exports = logger;
