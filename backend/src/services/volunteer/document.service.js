const AppError = require('../../utils/AppError');
const logger = require('../../utils/logger');
const { detectMimeType } = require('../../utils/fileSignature');
const {
  ALLOWED_DOCUMENT_MIME_TYPES,
  DOCUMENT_STATUS,
  REQUIRED_DOCUMENT_TYPES,
  VERIFICATION_STATUS: V,
  VOLUNTEER_STATUS,
} = require('../../config/constants');
const volunteerRepository = require('../../repositories/volunteer.repository');
const documentRepository = require('../../repositories/volunteerDocument.repository');
const { getDocumentStorage } = require('../../integrations/cloudinary/documentStorage');
const notificationService = require('../notification/notification.service');
const { documentView } = require('./volunteer.mapper');

async function storeFile(storage, volunteerId, documentType, buffer, mimeType) {
  try {
    return await storage.upload({
      buffer,
      mimeType,
      publicIdHint: `${volunteerId}_${documentType}_${Date.now()}`,
    });
  } catch (err) {
    if (err instanceof AppError) throw err;
    logger.error({ err }, 'Document upload to storage failed');
    throw new AppError('FILE_UPLOAD_FAILED', 'Could not store the document', { status: 502 });
  }
}

function hasAllRequired(documents) {
  return REQUIRED_DOCUMENT_TYPES.every((type) =>
    documents.some((d) => d.documentType === type && d.status !== DOCUMENT_STATUS.REJECTED),
  );
}

/**
 * Uploads or replaces a verification document. Once every required document
 * is on file, the volunteer is submitted for review (NOT_SUBMITTED/REJECTED ->
 * PENDING). Replacing a required document after approval also returns the
 * volunteer to PENDING (OQ-23), which makes them ineligible until re-approved.
 */
async function uploadDocument(volunteer, { documentType, file }) {
  if (!file?.buffer?.length) {
    throw AppError.validation([{ field: 'file', message: 'A file is required' }]);
  }
  const mimeType = detectMimeType(file.buffer);
  if (!mimeType || !ALLOWED_DOCUMENT_MIME_TYPES.includes(mimeType)) {
    throw new AppError('FILE_UPLOAD_FAILED', 'Only PDF, JPEG or PNG files are accepted');
  }
  if (volunteer.status === VOLUNTEER_STATUS.BUSY) {
    throw new AppError('VOLUNTEER_NOT_AVAILABLE', 'Resolve your current emergency first');
  }

  const storage = getDocumentStorage();
  const stored = await storeFile(storage, volunteer.id, documentType, file.buffer, mimeType);
  const previous = await documentRepository.findCurrent(volunteer._id, documentType);
  const document = await documentRepository.create({
    volunteerId: volunteer._id,
    documentType,
    ...stored,
    originalName: file.originalname?.slice(0, 200),
    mimeType,
    sizeBytes: file.size ?? file.buffer.length,
  });
  if (previous) {
    await documentRepository.markReplaced(previous._id);
    // Keep only what is needed (doc 22): delete the superseded file.
    storage.remove(previous).catch((err) => logger.warn({ err }, 'Old document not deleted'));
  }

  const documents = await documentRepository.listCurrent(volunteer._id);
  const replacesApproved =
    volunteer.verificationStatus === V.APPROVED && REQUIRED_DOCUMENT_TYPES.includes(documentType);
  const awaitingSubmission = [V.NOT_SUBMITTED, V.REJECTED].includes(volunteer.verificationStatus);

  let verificationStatus = volunteer.verificationStatus;
  if (hasAllRequired(documents) && (awaitingSubmission || replacesApproved)) {
    const update = {
      $set: { verificationStatus: V.PENDING, submittedAt: new Date(), rejectionReason: null },
    };
    if (volunteer.status === VOLUNTEER_STATUS.ACTIVE) {
      update.$set.status = VOLUNTEER_STATUS.OFFLINE;
      update.$set.statusChangedAt = new Date();
      update.$unset = { currentLocation: '', locationAccuracy: '', locationUpdatedAt: '' };
    }
    const updated = await volunteerRepository.updateById(volunteer._id, update);
    verificationStatus = updated.verificationStatus;
    await notificationService.notifyAdmins({
      type: notificationService.EVENTS.VERIFICATION_SUBMITTED,
      data: { volunteerId: volunteer.id },
    });
  }

  return { document: documentView(document), verificationStatus };
}

module.exports = { uploadDocument, hasAllRequired };
