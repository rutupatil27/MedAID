const { Router } = require('express');
const controller = require('../controllers/user.controller');
const schemas = require('../validators/user.validator');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/authenticate');

const router = Router();

// Any authenticated account may read its own profile, even before a forced
// password change, so the app can route correctly.
router.get('/me', authenticate, controller.getMe);
router.patch('/me', authenticate, validate(schemas.updateMe), controller.updateMe);

module.exports = router;
