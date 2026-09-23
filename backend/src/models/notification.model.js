const { Schema, model } = require('mongoose');
const { applyToJSON } = require('./schemaHelpers');

/** In-app notification record. `data` holds IDs and event types only (doc 19). */
const notificationSchema = new Schema(
  {
    recipientUserId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    type: { type: String, required: true },
    title: { type: String, required: true, maxlength: 150 },
    body: { type: String, required: true, maxlength: 500 },
    data: { type: Map, of: String, default: () => new Map() },
    readAt: { type: Date, default: null },
  },
  { timestamps: { createdAt: true, updatedAt: false } },
);

notificationSchema.index({ recipientUserId: 1, createdAt: -1 });
notificationSchema.index({ recipientUserId: 1, readAt: 1 });
applyToJSON(notificationSchema);

module.exports = model('Notification', notificationSchema);
