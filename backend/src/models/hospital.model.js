const { Schema, model } = require('mongoose');
const { HOSPITAL_SOURCES } = require('../config/constants');
const { pointSchema, applyToJSON } = require('./schemaHelpers');

const hospitalSchema = new Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 160 },
    location: { type: pointSchema, required: true },
    address: { type: String, trim: true, maxlength: 300 },
    contact: {
      phone: { type: String, trim: true, maxlength: 20 },
    },
    services: [{ type: String, trim: true, maxlength: 80 }],
    hasEmergencyDepartment: { type: Boolean, default: false },
    source: {
      provider: {
        type: String,
        enum: Object.values(HOSPITAL_SOURCES),
        default: HOSPITAL_SOURCES.MANUAL,
      },
      externalId: { type: String, trim: true },
    },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true },
);

hospitalSchema.index({ location: '2dsphere' });
applyToJSON(hospitalSchema);

module.exports = model('Hospital', hospitalSchema);
