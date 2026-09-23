const { Router } = require('express');
const controller = require('../controllers/auth.controller');
const schemas = require('../validators/auth.validator');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/authenticate');
const { authLimiter } = require('../middleware/rateLimiter');

const router = Router();

router.post('/register', authLimiter, validate(schemas.register), controller.register);
router.post('/login', authLimiter, validate(schemas.login), controller.login);
router.post('/refresh', authLimiter, validate(schemas.refreshToken), controller.refresh);
router.post('/logout', validate(schemas.logout), controller.logout);
router.post(
  '/change-password',
  authLimiter,
  authenticate,
  validate(schemas.changePassword),
  controller.changePassword,
);

module.exports = router;
