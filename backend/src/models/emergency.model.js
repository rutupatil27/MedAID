const { Schema, model } = require('mongoose');
const { EMERGENCY_STATUS } = require('../config/constants');
const { pointSchema, applyToJSON } = require('./schemaHelpers');

const statusHistorySchema = new Schema(
  {
    status: { type: String, enum: Object.values(EMERGENCY_STATUS), required: true },
    at: { type: Date, required: true },
    by: { type: Schema.Types.ObjectId, ref: 'User' },
    note: { type: String, maxlength: 300 },
  },
  { _id: false },
);

const emergencySchema = new Schema(
  {
    alertNumber: { type: String, required: true, unique: true },
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },

    /** Absent when the user had no location fix (OQ-15). */
    location: { type: pointSchema, default: undefined },
    locationAccuracy: { type: Number, min: 0 },
    message: { type: String, trim: true, maxlength: 500 },

    status: {
      type: String,
      enum: Object.values(EMERGENCY_STATUS),
      default: EMERGENCY_STATUS.CREATED,
    },
    /** Mirrors "status is not terminal"; backs the one-open-emergency index (P-08). */
    isOpen: { type: Boolean, default: true },
    statusHistory: { type: [statusHistorySchema], default: [] },

    assignedVolunteerId: { type: Schema.Types.ObjectId, ref: 'Volunteer', default: null },
    currentAssignmentId: { type: Schema.Types.ObjectId, ref: 'EmergencyAssignment', default: null },
    attemptCount: { type: Number, default: 0 },
    /** Volunteers who already expired/declined for this emergency. */
    excludedVolunteerIds: [{ type: Schema.Types.ObjectId, ref: 'Volunteer' }],

    /** Short lock so only one engine run processes an emergency at a time. */
    assignmentLockUntil: { type: Date, default: null },
    lastAdminAlertAt: { type: Date },

    idempotencyKey: { type: String, trim: true, maxlength: 100 },

    assignedAt: { type: Date },
    acceptedAt: { type: Date },
    startedAt: { type: Date },
    resolvedAt: { type: Date },
    resolvedBy: { type: Schema.Types.ObjectId, ref: 'User' },
    resolutionNote: { type: String, trim: true, maxlength: 1000 },
    cancelledAt: { type: Date },
    cancelledBy: { type: Schema.Types.ObjectId, ref: 'User' },
    cancelReason: { type: String, trim: true, maxlength: 500 },
    unassignedAt: { type: Date },
  },
  { timestamps: true },
);

emergencySchema.index({ status: 1, createdAt: -1 });
emergencySchema.index({ assignedVolunteerId: 1, status: 1 });
emergencySchema.index({ userId: 1, createdAt: -1 });
emergencySchema.index({ location: '2dsphere' });
// Database-level guarantee: at most one open emergency per user.
emergencySchema.index(
  { userId: 1 },
  { unique: true, partialFilterExpression: { isOpen: true }, name: 'one_open_emergency_per_user' },
);
emergencySchema.index(
  { userId: 1, idempotencyKey: 1 },
  { unique: true, partialFilterExpression: { idempotencyKey: { $type: 'string' } } },
);

applyToJSON(emergencySchema, ['assignmentLockUntil', 'idempotencyKey']);

module.exports = model('Emergency', emergencySchema);
