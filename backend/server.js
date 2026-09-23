const env = require('./src/config/env');
const logger = require('./src/utils/logger');
require('./src/models');
const { connectDatabase, disconnectDatabase } = require('./src/config/database');
const { createApp } = require('./src/app');
const { registerAllJobs } = require('./src/jobs');
const { startJobs, stopJobs } = require('./src/jobs/scheduler');
const assignmentService = require('./src/services/assignment/assignment.service');
const notificationService = require('./src/services/notification/notification.service');

async function main() {
  await connectDatabase(env.mongodbUri);

  const app = createApp();
  const server = app.listen(env.port, () => {
    logger.info({ port: env.port, env: env.nodeEnv }, 'MedAID API listening');
  });

  if (env.jobsEnabled) {
    registerAllJobs();
    startJobs();
  }

  let shuttingDown = false;
  const shutdown = (signal) => {
    if (shuttingDown) return;
    shuttingDown = true;
    logger.info({ signal }, 'Shutting down');
    stopJobs();
    server.close(async () => {
      await assignmentService.whenIdle();
      await notificationService.whenIdle();
      await disconnectDatabase();
      process.exit(0);
    });
    setTimeout(() => process.exit(1), 10000).unref();
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

main().catch((err) => {
  logger.fatal({ err }, 'Failed to start MedAID API');
  process.exit(1);
});
