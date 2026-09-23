const { Schema, model } = require('mongoose');
const { pointSchema, applyToJSON } = require('./schemaHelpers');

const contactSchema = new Schema(
  {
    name: { type: String, trim: true, maxlength: 100 },
    phone: { type: String, trim: true, maxlength: 20 },
  },
  { _id: false },
);

/**
 * Temporary medical camp (doc 21). Visible to Users only while
 * isActive && startDateTime <= now <= endDateTime (D-012).
 */
const medicalCampSchema = new Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 120 },
    description: { type: String, trim: true, maxlength: 1000 },
    location: { type: pointSchema, required: true },
    address: { type: String, required: true, trim: true, maxlength: 300 },
    services: [{ type: String, trim: true, maxlength: 80 }],
    contact: { type: contactSchema, default: () => ({}) },
    startDateTime: { type: Date, required: true },
    endDateTime: {
      type: Date,
      required: true,
      validate: {
        validator(value) {
          return !this.startDateTime || value > this.startDateTime;
        },
        message: 'endDateTime must be after startDateTime',
      },
    },
    isActive: { type: Boolean, default: true },
    /** Soft delete keeps historical references valid (A-13). */
    isDeleted: { type: Boolean, default: false },
    deletedAt: { type: Date },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User' },
    updatedBy: { type: Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true },
);

medicalCampSchema.index({ location: '2dsphere' });
medicalCampSchema.index({ isActive: 1, isDeleted: 1, startDateTime: 1, endDateTime: 1 });
applyToJSON(medicalCampSchema, ['isDeleted', 'deletedAt']);

module.exports = model('MedicalCamp', medicalCampSchema);
