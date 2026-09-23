const { Router } = require('express');
const controller = require('../controllers/facility.controller');
const schemas = require('../validators/facility.validator');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/authenticate');
const { authorize } = require('../middleware/authorize');

/** Mounted at the API root: /facilities, /hospitals and /medical-camps. */
const router = Router();
const signedIn = [authenticate, authorize('USER', 'VOLUNTEER', 'ADMIN')];

router.get('/facilities/nearby', signedIn, validate(schemas.nearby), controller.nearbyFacilities);
router.get(
  '/hospitals/nearby',
  signedIn,
  validate(schemas.nearbyOfOneType),
  controller.nearbyHospitals,
);
router.get('/hospitals/:id', signedIn, validate(schemas.byId), controller.getHospital);
router.get(
  '/medical-camps/nearby',
  signedIn,
  validate(schemas.nearbyOfOneType),
  controller.nearbyCamps,
);
router.get('/medical-camps/:id', signedIn, validate(schemas.byId), controller.getCamp);

module.exports = router;
