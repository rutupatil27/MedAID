const mongoose = require('mongoose');
const logger = require('../utils/logger');

mongoose.set('strictQuery', true);

async function connectDatabase(uri, options = {}) {
  await mongoose.connect(uri, { serverSelectionTimeoutMS: 10000, ...options });
  await Promise.all(Object.values(mongoose.models).map((model) => model.init()));
  logger.info({ transactions: supportsTransactions() }, 'MongoDB connected');
}

async function disconnectDatabase() {
  await mongoose.disconnect();
}

function isDatabaseConnected() {
  return mongoose.connection.readyState === 1;
}

/** Transactions need a replica set or sharded cluster (R-12). */
function supportsTransactions() {
  const client = mongoose.connection.getClient?.();
  const type = client?.topology?.description?.type;
  return ['ReplicaSetWithPrimary', 'Sharded', 'LoadBalanced'].includes(type);
}

module.exports = {
  connectDatabase,
  disconnectDatabase,
  isDatabaseConnected,
  supportsTransactions,
};
