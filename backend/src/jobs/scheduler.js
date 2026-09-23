const logger = require('../utils/logger');

/**
 * Minimal in-process interval scheduler (P-06). Jobs are database-driven and
 * idempotent, so a restart simply resumes scanning. Assumes one backend instance.
 */
const registered = [];
const timers = [];
let running = false;

/**
 * @param {{ name: string, intervalMs: number, run: () => Promise<void>, runOnStart?: boolean }} job
 */
function registerJob(job) {
  registered.push(job);
}

function schedule(job) {
  let busy = false;
  const tick = async () => {
    if (busy) return; // never overlap runs of the same job
    busy = true;
    try {
      await job.run();
    } catch (err) {
      logger.error({ err, job: job.name }, 'Scheduled job failed');
    } finally {
      busy = false;
    }
  };
  if (job.runOnStart) void tick();
  const timer = setInterval(tick, job.intervalMs);
  timer.unref();
  timers.push(timer);
}

function startJobs() {
  if (running) return;
  running = true;
  registered.forEach(schedule);
  logger.info({ jobs: registered.map((j) => j.name) }, 'Background jobs started');
}

function stopJobs() {
  timers.splice(0).forEach(clearInterval);
  running = false;
}

module.exports = { registerJob, startJobs, stopJobs };
