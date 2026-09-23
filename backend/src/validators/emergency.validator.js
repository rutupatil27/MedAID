const Joi = require('joi');
const AppError = require('../utils/AppError');
const { idParams, latitude, longitude, pagination } = require('./common.validator');

const create = {
  body: Joi.object({
    latitude,
    longitude,
    accuracy: Joi.number().min(0).max(100000),
    message: Joi.string().trim().max(500).allow(''),
  }).and('latitude', 'longitude'),
};

const listMine = {
  query: Joi.object({ ...pagination, open: Joi.boolean() }),
};

const byId = { params: idParams };

const cancel = {
  params: idParams,
  body: Joi.object({ reason: Joi.string().trim().max(300).allow('') }),
};

const IDEMPOTENCY_KEY = /^[A-Za-z0-9_-]{8,100}$/;

/** Reads and validates the optional `Idempotency-Key` header (P-08). */
function idempotencyKeyFrom(req) {
  const key = req.get('idempotency-key');
  if (key === undefined) return undefined;
  if (!IDEMPOTENCY_KEY.test(key)) {
    throw AppError.validation([
      { field: 'headers.idempotency-key', message: 'Must be 8-100 letters, digits, - or _' },
    ]);
  }
  return key;
}

module.exports = { create, listMine, byId, cancel, idempotencyKeyFrom };
