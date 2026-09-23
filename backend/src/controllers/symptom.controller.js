const symptomService = require('../services/symptom/symptom.service');
const { resolveLanguage } = require('../utils/i18n');
const { sendSuccess } = require('../utils/apiResponse');

function list(req, res) {
  sendSuccess(res, { data: symptomService.listSymptoms(resolveLanguage(req)) });
}

function check(req, res) {
  sendSuccess(res, { data: symptomService.checkSymptoms(req.body, resolveLanguage(req)) });
}

module.exports = { list, check };
