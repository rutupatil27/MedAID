const Joi = require('joi');

const objectId = Joi.string().hex().length(24);

const idParams = Joi.object({ id: objectId.required() });

const latitude = Joi.number().min(-90).max(90);
const longitude = Joi.number().min(-180).max(180);

const coordinates = {
  latitude: latitude.required(),
  longitude: longitude.required(),
};

const pagination = {
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
};

const phone = Joi.string()
  .trim()
  .pattern(/^\+?[0-9][0-9\s-]{6,18}$/)
  .messages({ 'string.pattern.base': '{{#label}} must be a valid phone number' });

module.exports = { objectId, idParams, latitude, longitude, coordinates, pagination, phone };
