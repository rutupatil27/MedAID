const facilityService = require('../services/facility/facility.service');
const { sendSuccess } = require('../utils/apiResponse');

async function nearbyFacilities(req, res) {
  sendSuccess(res, { data: await facilityService.nearbyFacilities(req.validated.query) });
}

async function nearbyHospitals(req, res) {
  sendSuccess(res, { data: await facilityService.nearbyHospitals(req.validated.query) });
}

async function nearbyCamps(req, res) {
  sendSuccess(res, { data: await facilityService.nearbyCamps(req.validated.query) });
}

async function getHospital(req, res) {
  sendSuccess(res, { data: await facilityService.getHospital(req.validated.params.id) });
}

async function getCamp(req, res) {
  sendSuccess(res, { data: await facilityService.getValidCamp(req.validated.params.id) });
}

module.exports = { nearbyFacilities, nearbyHospitals, nearbyCamps, getHospital, getCamp };
