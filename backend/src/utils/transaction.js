const mongoose = require('mongoose');
const { supportsTransactions } = require('../config/database');

/**
 * Runs `work(session)` inside a transaction when the deployment supports it,
 * otherwise runs it without a session. Race safety never depends on the
 * transaction alone: every state change also uses conditional updates.
 *
 * `work` may be retried by the driver on transient errors, so it must not
 * trigger side effects (notifications, pushes). Do those after it returns.
 */
async function withTransaction(work) {
  if (!supportsTransactions()) return work(null);

  const session = await mongoose.startSession();
  try {
    let result;
    await session.withTransaction(async () => {
      result = await work(session);
    });
    return result;
  } finally {
    await session.endSession();
  }
}

module.exports = { withTransaction };
