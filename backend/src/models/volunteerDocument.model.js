const { Schema, model } = require('mongoose');
const { DOCUMENT_TYPES, DOCUMENT_STATUS } = require('../config/constants');
const { applyToJSON } = require('./schemaHelpers');

/**
 * Metadata for a volunteer document stored in Cloudinary (D-011).
 * The file itself never enters MongoDB, and the storage reference stays
 * server-side: admins view files through short-lived signed URLs (P-12).
 */
const volunteerDocumentSchema = new Schema(
  {
    volunteerId: { type: Schema.Types.ObjectId, ref: 'Volunteer', required: true, index: true },
    documentType: { type: String, enum: Object.values(DOCUMENT_TYPES), required: true },
    storageProvider: { type: String, default: 'CLOUDINARY' },
    publicId: { type: String, required: true },
    resourceType: { type: String, enum: ['image', 'raw'], required: true },
    deliveryType: { type: String, default: 'authenticated' },
    format: { type: String },
    originalName: { type: String, trim: true, maxlength: 200 },
    mimeType: { type: String, required: true },
    sizeBytes: { type: Number, required: true },
    status: {
      type: String,
      enum: Object.values(DOCUMENT_STATUS),
      default: DOCUMENT_STATUS.PENDING,
    },
    uploadedAt: { type: Date, default: Date.now },
    reviewedAt: { type: Date },
    reviewedBy: { type: Schema.Types.ObjectId, ref: 'User' },
    reviewNote: { type: String, trim: true, maxlength: 500 },
  },
  { timestamps: true },
);

volunteerDocumentSchema.index({ volunteerId: 1, documentType: 1, status: 1 });
applyToJSON(volunteerDocumentSchema, ['publicId', 'deliveryType', 'storageProvider']);

module.exports = model('VolunteerDocument', volunteerDocumentSchema);
