const { Schema, model } = require('mongoose');
const { ROLES, ACCOUNT_STATUS, LANGUAGES, GENDERS, BLOOD_GROUPS } = require('../config/constants');
const { applyToJSON } = require('./schemaHelpers');

/** Optional medical information a User may share with responders (OQ-16). */
const medicalProfileSchema = new Schema(
  {
    dateOfBirth: { type: Date },
    gender: { type: String, enum: Object.values(GENDERS) },
    bloodGroup: { type: String, enum: BLOOD_GROUPS },
    allergies: { type: String, trim: true, maxlength: 500 },
    medicalConditions: { type: String, trim: true, maxlength: 500 },
    emergencyContactName: { type: String, trim: true, maxlength: 100 },
    emergencyContactPhone: { type: String, trim: true, maxlength: 20 },
    /** Explicit consent to show this profile to the assigned volunteer. */
    shareWithResponders: { type: Boolean, default: false },
  },
  { _id: false },
);

/** Every account (USER, VOLUNTEER, ADMIN) lives in this collection (P-03). */
const userSchema = new Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 100 },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    username: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true, select: false },
    phone: { type: String, trim: true, maxlength: 20 },
    role: { type: String, enum: Object.values(ROLES), default: ROLES.USER, index: true },
    accountStatus: {
      type: String,
      enum: Object.values(ACCOUNT_STATUS),
      default: ACCOUNT_STATUS.ACTIVE,
    },
    preferredLanguage: { type: String, enum: LANGUAGES, default: 'en' },
    mustChangePassword: { type: Boolean, default: false },
    medicalProfile: { type: medicalProfileSchema, default: () => ({}) },
    lastLoginAt: { type: Date },
    passwordChangedAt: { type: Date },
    suspendedAt: { type: Date },
    suspendedBy: { type: Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true },
);

userSchema.index({ role: 1, createdAt: -1 });
applyToJSON(userSchema);

module.exports = model('User', userSchema);
