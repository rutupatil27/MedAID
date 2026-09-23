const Joi = require('joi');
const { LANGUAGES, GENDERS, BLOOD_GROUPS } = require('../config/constants');
const { phone } = require('./common.validator');

const medicalProfile = Joi.object({
  dateOfBirth: Joi.date().iso().max('now').allow(null),
  gender: Joi.string()
    .valid(...Object.values(GENDERS))
    .allow(null),
  bloodGroup: Joi.string()
    .valid(...BLOOD_GROUPS)
    .allow(null),
  allergies: Joi.string().trim().max(500).allow(''),
  medicalConditions: Joi.string().trim().max(500).allow(''),
  emergencyContactName: Joi.string().trim().max(100).allow(''),
  emergencyContactPhone: phone.allow(''),
  shareWithResponders: Joi.boolean(),
});

const updateMe = {
  body: Joi.object({
    name: Joi.string().trim().min(2).max(100),
    phone: phone.allow(''),
    preferredLanguage: Joi.string().valid(...LANGUAGES),
    medicalProfile,
  }).min(1),
};

module.exports = { updateMe, medicalProfile };
