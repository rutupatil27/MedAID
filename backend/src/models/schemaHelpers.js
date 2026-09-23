const { Schema } = require('mongoose');

/** GeoJSON Point sub-schema. Coordinates are [longitude, latitude]. */
const pointSchema = new Schema(
  {
    type: { type: String, enum: ['Point'], required: true, default: 'Point' },
    coordinates: {
      type: [Number],
      required: true,
      validate: {
        validator: (c) =>
          Array.isArray(c) &&
          c.length === 2 &&
          c[0] >= -180 &&
          c[0] <= 180 &&
          c[1] >= -90 &&
          c[1] <= 90,
        message: 'coordinates must be [longitude, latitude]',
      },
    },
  },
  { _id: false },
);

/**
 * Consistent JSON output: `id` instead of `_id`, no `__v`, and never any
 * secret fields (doc 09: never return passwordHash).
 */
function applyToJSON(schema, hiddenFields = []) {
  const hidden = ['__v', 'passwordHash', ...hiddenFields];
  schema.set('toJSON', {
    virtuals: false,
    versionKey: false,
    transform(_doc, ret) {
      ret.id = ret._id?.toString();
      delete ret._id;
      for (const field of hidden) delete ret[field];
      return ret;
    },
  });
}

module.exports = { pointSchema, applyToJSON };
