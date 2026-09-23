const volunteerService = require('../services/volunteer/volunteer.service');
const documentService = require('../services/volunteer/document.service');
const responseService = require('../services/emergency/response.service');
const routeService = require('../services/emergency/route.service');
const { sendSuccess } = require('../utils/apiResponse');

async function getMe(req, res) {
  sendSuccess(res, { data: await volunteerService.viewOf(req.volunteer) });
}

async function updateMe(req, res) {
  sendSuccess(res, {
    message: 'Profile updated',
    data: await volunteerService.updateProfile(req.volunteer, req.body),
  });
}

async function uploadDocument(req, res) {
  sendSuccess(res, {
    status: 201,
    message: 'Document uploaded',
    data: await documentService.uploadDocument(req.volunteer, {
      documentType: req.body.documentType,
      file: req.file,
    }),
  });
}

async function getVerification(req, res) {
  const view = await volunteerService.viewOf(req.volunteer);
  sendSuccess(res, {
    data: {
      verificationStatus: view.verificationStatus,
      rejectionReason: view.rejectionReason,
      submittedAt: view.submittedAt,
      verifiedAt: view.verifiedAt,
      profileCompleted: view.profileCompleted,
      requiredDocuments: view.requiredDocuments,
      documents: view.documents,
    },
  });
}

async function setStatus(req, res) {
  sendSuccess(res, {
    message: 'Availability updated',
    data: await volunteerService.setAvailability(req.volunteer, req.body),
  });
}

async function updateLocation(req, res) {
  sendSuccess(res, { data: await volunteerService.updateLocation(req.volunteer, req.body) });
}

async function listEmergencies(req, res) {
  sendSuccess(res, {
    data: await responseService.listForVolunteer(req.volunteer, req.validated.query),
  });
}

async function getEmergency(req, res) {
  sendSuccess(res, {
    data: await responseService.getForVolunteer(req.volunteer, req.validated.params.id),
  });
}

async function getRoute(req, res) {
  sendSuccess(res, {
    data: await routeService.routeForVolunteer(req.volunteer, req.validated.params.id),
  });
}

async function accept(req, res) {
  sendSuccess(res, {
    message: 'Emergency accepted',
    data: await responseService.accept(req.volunteer, req.validated.params.id),
  });
}

async function decline(req, res) {
  sendSuccess(res, {
    message: 'Emergency declined',
    data: await responseService.decline(req.volunteer, req.validated.params.id, req.body),
  });
}

async function start(req, res) {
  sendSuccess(res, {
    message: 'Response started',
    data: await responseService.start(req.volunteer, req.validated.params.id),
  });
}

async function resolve(req, res) {
  sendSuccess(res, {
    message: 'Emergency resolved',
    data: await responseService.resolve(req.volunteer, req.validated.params.id, req.body),
  });
}

module.exports = {
  getMe,
  updateMe,
  uploadDocument,
  getVerification,
  setStatus,
  updateLocation,
  listEmergencies,
  getEmergency,
  getRoute,
  accept,
  decline,
  start,
  resolve,
};
