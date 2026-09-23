const emergencyService = require('../services/emergency/emergency.service');
const { idempotencyKeyFrom } = require('../validators/emergency.validator');
const { sendSuccess } = require('../utils/apiResponse');

async function create(req, res) {
  const { emergency, created } = await emergencyService.createEmergency(req.user.id, req.body, {
    idempotencyKey: idempotencyKeyFrom(req),
  });
  sendSuccess(res, {
    status: created ? 201 : 200,
    message: created ? 'Emergency alert created' : 'Existing open emergency returned',
    data: await emergencyService.toDetailedUserView(emergency),
  });
}

async function listMine(req, res) {
  sendSuccess(res, {
    data: await emergencyService.listForUser(req.user.id, req.validated.query),
  });
}

async function getMine(req, res) {
  sendSuccess(res, {
    data: await emergencyService.getForUser(req.user.id, req.validated.params.id),
  });
}

async function cancel(req, res) {
  sendSuccess(res, {
    message: 'Emergency cancelled',
    data: await emergencyService.cancelByUser(req.user.id, req.validated.params.id, req.body),
  });
}

module.exports = { create, listMine, getMine, cancel };
