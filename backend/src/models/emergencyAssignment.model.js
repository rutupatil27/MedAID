const { Schema, model } = require('mongoose');
const { ASSIGNMENT_STATUS, DISTANCE_SOURCE } = require('../config/constants');
const { applyToJSON } = require('./schemaHelpers');

/** One dispatch attempt of an emergency to a volunteer. History is never deleted. */
const emergencyAssignmentSchema = new Schema(
  {
    emergencyId: { type: Schema.Types.ObjectId, ref: 'Emergency', required: true },
    volunteerId: { type: Schema.Types.ObjectId, ref: 'Volunteer', required: true },
    attemptNumber: { type: Number, required: true, min: 1 },
    routeDistanceMeters: { type: Number, min: 0 },
    estimatedDurationSeconds: { type: Number, min: 0 },
    distanceSource: { type: String, enum: Object.values(DISTANCE_SOURCE) },

    status: {
      type: String,
      enum: Object.values(ASSIGNMENT_STATUS),
      default: ASSIGNMENT_STATUS.PENDING,
    },
    /** True while PENDING or ACCEPTED; backs the uniqueness guards below. */
    isActive: { type: Boolean, default: true },

    dispatchedAt: { type: Date, required: true },
    expiresAt: { type: Date, required: true },
    expiryWarningSentAt: { type: Date },
    acceptedAt: { type: Date },
    declinedAt: { type: Date },
    expiredAt: { type: Date },
    cancelledAt: { type: Date },
    completedAt: { type: Date },
    endReason: { type: String, trim: true, maxlength: 200 },
    assignedBy: { type: Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true },
);

emergencyAssignmentSchema.index({ emergencyId: 1, status: 1 });
emergencyAssignmentSchema.index({ status: 1, expiresAt: 1 });
emergencyAssignmentSchema.index({ volunteerId: 1, createdAt: -1 });
// Database-level race guards: one active assignment per emergency and per volunteer.
emergencyAssignmentSchema.index(
  { emergencyId: 1 },
  { unique: true, partialFilterExpression: { isActive: true }, name: 'one_active_per_emergency' },
);
emergencyAssignmentSchema.index(
  { volunteerId: 1 },
  { unique: true, partialFilterExpression: { isActive: true }, name: 'one_active_per_volunteer' },
);

applyToJSON(emergencyAssignmentSchema);

module.exports = model('EmergencyAssignment', emergencyAssignmentSchema);
