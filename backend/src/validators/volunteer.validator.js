const Joi = require('joi');
const { DOCUMENT_TYPES, GENDERS } = require('../config/constants');
const { idParams, latitude, longitude, pagination, phone } = require('./common.validator');

const updateProfile = {
  body: Joi.object({
    phone: phone.allow(''),
    dateOfBirth: Joi.date().iso().max('now').allow(null),
    gender: Joi.string()
      .valid(...Object.values(GENDERS))
      .allow(null),
    address: Joi.string().trim().max(300).allow(''),
    city: Joi.string().trim().max(100).allow(''),
    languages: Joi.array().items(Joi.string().trim().max(40)).max(10),
    skills: Joi.array().items(Joi.string().trim().max(60)).max(20),
    emergencyContactName: Joi.string().trim().max(100).allow(''),
    emergencyContactPhone: phone.allow(''),
  }).min(1),
};

const uploadDocument = {
  body: Joi.object({
    documentType: Joi.string()
      .valid(...Object.values(DOCUMENT_TYPES))
      .required(),
  }),
};

const setStatus = {
  body: Joi.object({
    status: Joi.string().valid('ACTIVE', 'OFFLINE').required(),
    latitude,
    longitude,
    accuracy: Joi.number().min(0).max(100000),
  }).and('latitude', 'longitude'),
};

const updateLocation = {
  body: Joi.object({
    latitude: latitude.required(),
    longitude: longitude.required(),
    accuracy: Joi.number().min(0).max(100000),
  }),
};

const listEmergencies = {
  query: Joi.object({
    ...pagination,
    scope: Joi.string().valid('ACTIVE', 'HISTORY').default('ACTIVE'),
  }),
};

const byId = { params: idParams };

const decline = {
  params: idParams,
  body: Joi.object({ reason: Joi.string().trim().max(300).allow('') }),
};

const resolve = {
  params: idParams,
  body: Joi.object({ resolutionNote: Joi.string().trim().min(3).max(1000).required() }),
};

module.exports = {
  updateProfile,
  uploadDocument,
  setStatus,
  updateLocation,
  listEmergencies,
  byId,
  decline,
  resolve,
};
