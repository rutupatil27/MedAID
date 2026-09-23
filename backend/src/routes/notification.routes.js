const { Router } = require('express');
const c = require('../controllers/notification.controller');
const s = require('../validators/notification.validator');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/authenticate');
const { authorize } = require('../middleware/authorize');

/** Notification center, shared by every role and scoped to "me" (doc 19). */
const router = Router();

router.use(authenticate, authorize());

router.get('/', validate(s.list), c.list);
router.get('/unread-count', c.unreadCount);
router.post('/read-all', c.markAllRead);
router.patch('/:id/read', validate(s.byId), c.markRead);

module.exports = router;
