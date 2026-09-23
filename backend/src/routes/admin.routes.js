const { Router } = require('express');
const c = require('../controllers/admin.controller');
const s = require('../validators/admin.validator');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/authenticate');
const { authorize } = require('../middleware/authorize');

/** Admin console API (doc 09). Every route requires the ADMIN role. */
const router = Router();

router.use(authenticate, authorize('ADMIN'));

router.get('/dashboard', c.dashboard);
router.get('/reports/summary', validate(s.report), c.report);
router.post('/notices', validate(s.notice), c.sendNotice);

router.post('/volunteers', validate(s.createVolunteer), c.createVolunteer);
router.get('/volunteers', validate(s.listVolunteers), c.listVolunteers);
router.get('/volunteers/locations', c.volunteerLocations);
router.get('/volunteers/:id', validate(s.byId), c.getVolunteer);
router.get('/volunteers/:id/documents', validate(s.byId), c.volunteerDocuments);
router.post('/volunteers/:id/verify', validate(s.verify), c.verifyVolunteer);
router.post('/volunteers/:id/reject', validate(s.reject), c.rejectVolunteer);
router.patch('/volunteers/:id/status', validate(s.accountStatus), c.setVolunteerStatus);

router.get('/emergencies', validate(s.listEmergencies), c.listEmergencies);
router.get('/emergencies/:id', validate(s.byId), c.getEmergency);
router.get('/emergencies/:id/assignments', validate(s.byId), c.emergencyAssignments);
router.post('/emergencies/:id/reassign', validate(s.reassign), c.reassignEmergency);
router.post('/emergencies/:id/resolve', validate(s.closeEmergency), c.resolveEmergency);
router.post('/emergencies/:id/cancel', validate(s.closeEmergency), c.cancelEmergency);

router.post('/medical-camps', validate(s.createCamp), c.createCamp);
router.get('/medical-camps', validate(s.listCamps), c.listCamps);
router.get('/medical-camps/:id', validate(s.byId), c.getCamp);
router.patch('/medical-camps/:id', validate(s.updateCamp), c.updateCamp);
router.delete('/medical-camps/:id', validate(s.byId), c.deleteCamp);

router.get('/users', validate(s.listUsers), c.listUsers);
router.patch('/users/:id/status', validate(s.accountStatus), c.setUserStatus);

module.exports = router;
