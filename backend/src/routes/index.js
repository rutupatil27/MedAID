const { Router } = require('express');
const { getHealth } = require('../controllers/health.controller');
const authRoutes = require('./auth.routes');
const userRoutes = require('./user.routes');
const symptomRoutes = require('./symptom.routes');
const facilityRoutes = require('./facility.routes');
const emergencyRoutes = require('./emergency.routes');
const volunteerRoutes = require('./volunteer.routes');
const adminRoutes = require('./admin.routes');
const notificationRoutes = require('./notification.routes');
const deviceRoutes = require('./device.routes');

/** Mounts every route group under /api/v1. */
function createApiRouter() {
  const router = Router();

  router.get('/health', getHealth);
  router.use('/auth', authRoutes);
  router.use('/users', userRoutes);
  router.use('/symptoms', symptomRoutes);
  router.use('/emergencies', emergencyRoutes);
  router.use('/volunteers', volunteerRoutes);
  router.use('/admin', adminRoutes);
  router.use('/notifications', notificationRoutes);
  router.use('/devices', deviceRoutes);
  router.use('/', facilityRoutes);

  return router;
}

module.exports = { createApiRouter };
