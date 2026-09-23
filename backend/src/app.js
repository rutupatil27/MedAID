const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const pinoHttp = require('pino-http');

const env = require('./config/env');
const logger = require('./utils/logger');
const { createApiRouter } = require('./routes');
const { apiLimiter } = require('./middleware/rateLimiter');
const { notFound } = require('./middleware/notFound');
const { errorHandler } = require('./middleware/errorHandler');

function corsOptions() {
  return {
    // Native mobile clients send no Origin header; browsers must be allow-listed.
    origin(origin, callback) {
      if (!origin || env.corsOrigins.includes(origin)) return callback(null, true);
      return callback(null, false);
    },
    methods: ['GET', 'POST', 'PATCH', 'DELETE'],
    allowedHeaders: ['Authorization', 'Content-Type', 'Accept-Language', 'Idempotency-Key'],
    maxAge: 600,
  };
}

function createApp() {
  const app = express();

  app.disable('x-powered-by');
  app.set('trust proxy', env.trustProxy);

  app.use(helmet());
  app.use(cors(corsOptions()));
  app.use(express.json({ limit: '100kb' }));
  if (!env.isTest) {
    app.use(pinoHttp({ logger, autoLogging: { ignore: (req) => req.url.endsWith('/health') } }));
  }

  app.use('/api', apiLimiter);
  app.use('/api/v1', createApiRouter());

  app.use(notFound);
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
