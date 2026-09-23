const { Schema, model } = require('mongoose');
const { VERIFICATION_STATUS, VOLUNTEER_STATUS, GENDERS } = require('../config/constants');
const { pointSchema, applyToJSON } = require('./schemaHelpers');

const volunteerProfileSchema = new Schema(
  {
    phone: { type: String, trim: true, maxlength: 20 },
    dateOfBirth: { type: Date },
    gender: { type: String, enum: Object.values(GENDERS) },
    address: { type: String, trim: true, maxlength: 300 },
    city: { type: String, trim: true, maxlength: 100 },
    languages: [{ type: String, trim: true, maxlength: 40 }],
    skills: [{ type: String, trim: true, maxlength: 60 }],
    emergencyContactName: { type: String, trim: true, maxlength: 100 },
    emergencyContactPhone: { type: String, trim: true, maxlength: 20 },
  },
  { _id: false },
);

/**
 * Volunteer extension of a VOLUNTEER user (1:1). Verification, operational
 * availability and account suspension are independent fields (P-02).
 */
const volunteerSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    profile: { type: volunteerProfileSchema, default: () => ({}) },
    profileCompleted: { type: Boolean, default: false },

    verificationStatus: {
      type: String,
      enum: Object.values(VERIFICATION_STATUS),
      default: VERIFICATION_STATUS.NOT_SUBMITTED,
    },
    submittedAt: { type: Date },
    verifiedBy: { type: Schema.Types.ObjectId, ref: 'User' },
    verifiedAt: { type: Date },
    rejectionReason: { type: String, trim: true, maxlength: 500 },

    status: {
      type: String,
      enum: Object.values(VOLUNTEER_STATUS),
      default: VOLUNTEER_STATUS.OFFLINE,
    },
    statusChangedAt: { type: Date },

    /** Latest location only; cleared when the volunteer goes OFFLINE (OQ-33). */
    currentLocation: { type: pointSchema, default: undefined },
    locationAccuracy: { type: Number, min: 0 },
    locationUpdatedAt: { type: Date },

    /** Reservation used by the assignment engine (P-04). Null = free. */
    currentAssignmentId: { type: Schema.Types.ObjectId, ref: 'EmergencyAssignment', default: null },
    currentEmergencyId: { type: Schema.Types.ObjectId, ref: 'Emergency', default: null },

    lastActiveAt: { type: Date },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true },
);

volunteerSchema.index({ currentLocation: '2dsphere' });
volunteerSchema.index({ verificationStatus: 1, status: 1 });
applyToJSON(volunteerSchema);

module.exports = model('Volunteer', volunteerSchema);
