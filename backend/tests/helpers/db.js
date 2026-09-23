const crypto = require('node:crypto');
const mongoose = require('mongoose');
require('../../src/models');
const { connectDatabase, disconnectDatabase } = require('../../src/config/database');
const assignmentService = require('../../src/services/assignment/assignment.service');
const notificationService = require('../../src/services/notification/notification.service');
const osmHospitals = require('../../src/services/facility/osmHospitals.service');

async function whenIdle() {
  await assignmentService.whenIdle();
  await notificationService.whenIdle();
  await osmHospitals.whenSynced();
}

/**
 * Connects each test file to its own database on the shared in-memory replica
 * set and wipes collections between tests.
 */
function useTestDatabase() {
  beforeAll(async () => {
    const dbName = `medaid_test_${crypto.randomBytes(6).toString('hex')}`;
    await connectDatabase(process.env.MONGODB_URI, { dbName });
  });

  afterEach(async () => {
    // Let background engine work finish before wiping data.
    await whenIdle();
    const collections = await mongoose.connection.db.collections();
    await Promise.all(collections.map((c) => c.deleteMany({})));
  });

  afterAll(async () => {
    await whenIdle();
    await mongoose.connection.dropDatabase();
    await disconnectDatabase();
  });
}

module.exports = { useTestDatabase };
