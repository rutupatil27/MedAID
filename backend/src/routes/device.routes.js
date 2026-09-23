const { Router } = require('express');
const c = require('../controllers/notification.controller');
const s = require('../validators/notification.validator');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/authenticate');
const { authorize } = require('../middleware/authorize');

/** Push registration for the signed-in account's device (doc 19). */
const router = Router();

router.use(authenticate, authorize());

router.post('/', validate(s.registerDevice), c.registerDevice);
router.delete('/:token', validate(s.unregisterDevice), c.unregisterDevice);

module.exports = router;
