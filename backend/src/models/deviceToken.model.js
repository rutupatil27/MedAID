const { Schema, model } = require('mongoose');

/** FCM registration token for push delivery (Phase 10). */
const deviceTokenSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    token: { type: String, required: true, unique: true },
    platform: { type: String, enum: ['android', 'ios', 'web'], required: true },
    lastSeenAt: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

module.exports = model('DeviceToken', deviceTokenSchema);
