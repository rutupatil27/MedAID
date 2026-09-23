const { Router } = require('express');
const controller = require('../controllers/emergency.controller');
const schemas = require('../validators/emergency.validator');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/authenticate');
const { authorize } = require('../middleware/authorize');

/** User-side emergency endpoints. Volunteers and admins use their own routes. */
const router = Router();

router.use(authenticate, authorize('USER'));
router.post('/', validate(schemas.create), controller.create);
router.get('/my', validate(schemas.listMine), controller.listMine);
router.get('/:id', validate(schemas.byId), controller.getMine);
router.post('/:id/cancel', validate(schemas.cancel), controller.cancel);

module.exports = router;
