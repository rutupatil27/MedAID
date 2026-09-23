const { Router } = require('express');
const controller = require('../controllers/volunteer.controller');
const schemas = require('../validators/volunteer.validator');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/authenticate');
const { authorize } = require('../middleware/authorize');
const { loadVolunteer } = require('../middleware/loadVolunteer');
const { singleDocument } = require('../middleware/upload');

/** Volunteer self-service endpoints (doc 09). Everything is scoped to "me". */
const router = Router();

router.use(authenticate, authorize('VOLUNTEER'), loadVolunteer);

router.get('/me', controller.getMe);
router.patch('/me', validate(schemas.updateProfile), controller.updateMe);
router.post(
  '/me/documents',
  singleDocument,
  validate(schemas.uploadDocument),
  controller.uploadDocument,
);
router.get('/me/verification', controller.getVerification);
router.patch('/me/status', validate(schemas.setStatus), controller.setStatus);
router.post('/me/location', validate(schemas.updateLocation), controller.updateLocation);

router.get('/me/emergencies', validate(schemas.listEmergencies), controller.listEmergencies);
router.get('/me/emergencies/:id', validate(schemas.byId), controller.getEmergency);
router.get('/me/emergencies/:id/route', validate(schemas.byId), controller.getRoute);
router.post('/me/emergencies/:id/accept', validate(schemas.byId), controller.accept);
router.post('/me/emergencies/:id/decline', validate(schemas.decline), controller.decline);
router.post('/me/emergencies/:id/start', validate(schemas.byId), controller.start);
router.post('/me/emergencies/:id/resolve', validate(schemas.resolve), controller.resolve);

module.exports = router;
