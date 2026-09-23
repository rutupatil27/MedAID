const env = require('../config/env');
const assignmentService = require('../services/assignment/assignment.service');
const { registerJob } = require('./scheduler');

/** Registers all background jobs (P-06). Each is database-driven and idempotent. */
function registerAllJobs() {
  // Expiry warnings + 2-minute acceptance timeouts -> reassignment (D-008).
  registerJob({
    name: 'assignment-scan',
    intervalMs: env.assignment.scanIntervalMs,
    runOnStart: true,
    run: () => assignmentService.runAssignmentScan(),
  });
  // Retry emergencies still waiting for a volunteer, and recover stuck ones.
  registerJob({
    name: 'unassigned-retry',
    intervalMs: env.assignment.unassignedRetryIntervalMs,
    runOnStart: true,
    run: () => assignmentService.retryWaitingEmergencies(),
  });
}

module.exports = { registerAllJobs };
