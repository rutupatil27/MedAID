const AppError = require('../../utils/AppError');
const { toPoint } = require('../../utils/geo');
const campRepository = require('../../repositories/medicalCamp.repository');
const { toCampDto } = require('../facility/facility.service');

/** Admin view of a camp, including its lifecycle state. */
function toAdminCampView(camp, now = new Date()) {
  const lifecycle = !camp.isActive
    ? 'INACTIVE'
    : camp.endDateTime < now
      ? 'EXPIRED'
      : camp.startDateTime > now
        ? 'UPCOMING'
        : 'ACTIVE_NOW';
  return {
    ...toCampDto(camp),
    isActive: camp.isActive,
    lifecycle,
    createdAt: camp.createdAt,
    updatedAt: camp.updatedAt,
  };
}

function toDocument(input) {
  const doc = { ...input };
  if (input.latitude != null && input.longitude != null) {
    doc.location = toPoint(input);
  }
  delete doc.latitude;
  delete doc.longitude;
  return doc;
}

async function create(input, { adminUserId }) {
  const camp = await campRepository.create({ ...toDocument(input), createdBy: adminUserId });
  return toAdminCampView(camp);
}

async function list(query) {
  const { items, total } = await campRepository.list(query);
  return {
    items: items.map((c) => toAdminCampView(c)),
    page: query.page,
    limit: query.limit,
    total,
  };
}

async function get(campId) {
  const camp = await campRepository.findById(campId);
  if (!camp) throw AppError.notFound('Medical camp');
  return toAdminCampView(camp);
}

async function update(campId, changes, { adminUserId }) {
  const existing = await campRepository.findById(campId);
  if (!existing) throw AppError.notFound('Medical camp');
  const start = changes.startDateTime ?? existing.startDateTime;
  const end = changes.endDateTime ?? existing.endDateTime;
  if (end <= start) {
    throw AppError.validation([
      { field: 'body.endDateTime', message: 'endDateTime must be after startDateTime' },
    ]);
  }
  const camp = await campRepository.updateById(campId, {
    $set: { ...toDocument(changes), updatedBy: adminUserId },
  });
  return toAdminCampView(camp);
}

/** Soft delete keeps historical references valid (A-13). */
async function remove(campId, { adminUserId }) {
  const camp = await campRepository.updateById(campId, {
    $set: { isDeleted: true, isActive: false, deletedAt: new Date(), updatedBy: adminUserId },
  });
  if (!camp) throw AppError.notFound('Medical camp');
}

module.exports = { toAdminCampView, create, list, get, update, remove };
