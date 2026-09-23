const { MongoMemoryReplSet } = require('mongodb-memory-server');

/** Starts one in-memory replica set (transactions supported) for the whole run. */
module.exports = async function globalSetup() {
  const replSet = await MongoMemoryReplSet.create({
    replSet: { count: 1, storageEngine: 'wiredTiger' },
  });
  globalThis.__MONGO_REPLSET__ = replSet;
  process.env.MONGODB_URI = replSet.getUri();
};
