const { Schema, model } = require('mongoose');

/** Atomic sequences, e.g. human-readable emergency alert numbers. */
const counterSchema = new Schema(
  {
    _id: { type: String, required: true },
    seq: { type: Number, default: 0 },
  },
  { versionKey: false },
);

module.exports = model('Counter', counterSchema);
