const AppError = require('../../utils/AppError');
const { fromPoint } = require('../../utils/geo');
const hospitalRepository = require('../../repositories/hospital.repository');
const { ensureHospitalsNear } = require('./osmHospitals.service');
const campRepository = require('../../repositories/medicalCamp.repository');

const FACILITY_TYPE = Object.freeze({ HOSPITAL: 'HOSPITAL', CAMP: 'CAMP' });

const id = (doc) => (doc._id ?? doc.id).toString();

function toHospitalDto(doc) {
  return {
    id: id(doc),
    type: FACILITY_TYPE.HOSPITAL,
    name: doc.name,
    address: doc.address ?? null,
    location: fromPoint(doc.location),
    distanceMeters: doc.distanceMeters == null ? null : Math.round(doc.distanceMeters),
    services: doc.services ?? [],
    contact: { name: null, phone: doc.contact?.phone ?? null },
    hasEmergencyDepartment: Boolean(doc.hasEmergencyDepartment),
  };
}

function toCampDto(doc) {
  return {
    id: id(doc),
    type: FACILITY_TYPE.CAMP,
    name: doc.name,
    description: doc.description ?? null,
    address: doc.address ?? null,
    location: fromPoint(doc.location),
    distanceMeters: doc.distanceMeters == null ? null : Math.round(doc.distanceMeters),
    services: doc.services ?? [],
    contact: { name: doc.contact?.name ?? null, phone: doc.contact?.phone ?? null },
    startDateTime: doc.startDateTime,
    endDateTime: doc.endDateTime,
  };
}

async function nearbyHospitals(query) {
  // Top up this area from OpenStreetMap, so the map shows real hospitals and
  // not only the ones an admin has entered.
  await ensureHospitalsNear(query);
  return (await hospitalRepository.findNearby(query)).map(toHospitalDto);
}

async function nearbyCamps(query) {
  return (await campRepository.findNearbyValid(query)).map(toCampDto);
}

/** Hospitals and currently valid camps merged by distance (FR-04). */
async function nearbyFacilities({ type = 'ALL', ...query }) {
  const [hospitals, camps] = await Promise.all([
    type === FACILITY_TYPE.CAMP ? [] : nearbyHospitals(query),
    type === FACILITY_TYPE.HOSPITAL ? [] : nearbyCamps(query),
  ]);
  return [...hospitals, ...camps]
    .sort((a, b) => a.distanceMeters - b.distanceMeters)
    .slice(0, query.limit);
}

async function getHospital(hospitalId) {
  const doc = await hospitalRepository.findActiveById(hospitalId);
  if (!doc) throw AppError.notFound('Hospital');
  return toHospitalDto(doc);
}

async function getValidCamp(campId) {
  const doc = await campRepository.findValidById(campId);
  if (!doc) throw AppError.notFound('Medical camp');
  return toCampDto(doc);
}

module.exports = {
  FACILITY_TYPE,
  toCampDto,
  nearbyHospitals,
  nearbyCamps,
  nearbyFacilities,
  getHospital,
  getValidCamp,
};
