const Joi = require('joi');
const { coordinates, idParams } = require('./common.validator');

const nearbyQuery = {
  ...coordinates,
  radiusMeters: Joi.number().integer().min(100).max(50000).default(10000),
  limit: Joi.number().integer().min(1).max(100).default(30),
};

const nearby = {
  query: Joi.object({
    ...nearbyQuery,
    type: Joi.string().valid('ALL', 'HOSPITAL', 'CAMP').default('ALL'),
  }),
};

const nearbyOfOneType = { query: Joi.object(nearbyQuery) };

const byId = { params: idParams };

module.exports = { nearby, nearbyOfOneType, byId };
