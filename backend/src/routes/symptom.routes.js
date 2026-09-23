const { Router } = require('express');
const controller = require('../controllers/symptom.controller');
const schemas = require('../validators/symptom.validator');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/authenticate');
const { authorize } = require('../middleware/authorize');

const router = Router();

// Symptom checker is a User feature (doc 05).
router.use(authenticate, authorize('USER'));
router.get('/', controller.list);
router.post('/check', validate(schemas.check), controller.check);

module.exports = router;
