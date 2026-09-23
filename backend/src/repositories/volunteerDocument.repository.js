const { VolunteerDocument } = require('../models');
const { DOCUMENT_STATUS } = require('../config/constants');

/** Documents currently on file (replaced ones are kept for audit only). */
const CURRENT = { $ne: DOCUMENT_STATUS.REPLACED };

function create(data) {
  return VolunteerDocument.create(data);
}

function findById(id) {
  return VolunteerDocument.findById(id);
}

function listCurrent(volunteerId) {
  return VolunteerDocument.find({ volunteerId, status: CURRENT }).sort({ uploadedAt: -1 });
}

function findCurrent(volunteerId, documentType) {
  return VolunteerDocument.findOne({ volunteerId, documentType, status: CURRENT });
}

function markReplaced(id) {
  return VolunteerDocument.updateOne({ _id: id }, { $set: { status: DOCUMENT_STATUS.REPLACED } });
}

/** Records a verification decision on all of a volunteer's pending documents. */
function reviewPending(volunteerId, { status, reviewedBy, reviewNote }) {
  return VolunteerDocument.updateMany(
    { volunteerId, status: DOCUMENT_STATUS.PENDING },
    { $set: { status, reviewedBy, reviewNote, reviewedAt: new Date() } },
  );
}

module.exports = { create, findById, listCurrent, findCurrent, markReplaced, reviewPending };
