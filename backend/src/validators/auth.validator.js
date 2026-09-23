const Joi = require('joi');
const { LANGUAGES } = require('../config/constants');
const { phone } = require('./common.validator');

/** At least 8 characters with at least one letter and one digit. */
const password = Joi.string()
  .min(8)
  .max(128)
  .pattern(/[A-Za-z]/, 'letter')
  .pattern(/\d/, 'digit');

const username = Joi.string()
  .trim()
  .pattern(/^[a-zA-Z0-9_.]{3,30}$/)
  .messages({
    'string.pattern.base': '{{#label}} must be 3-30 letters, numbers, dots or underscores',
  });

const register = {
  body: Joi.object({
    name: Joi.string().trim().min(2).max(100).required(),
    email: Joi.string().trim().lowercase().email().max(254).required(),
    username: username.required(),
    password: password.required(),
    phone: phone.allow('').optional(),
    preferredLanguage: Joi.string()
      .valid(...LANGUAGES)
      .default('en'),
  }),
};

const login = {
  body: Joi.object({
    identifier: Joi.string().trim().min(3).max(254).required(),
    password: Joi.string().min(1).max(128).required(),
  }),
};

const refreshToken = {
  body: Joi.object({
    refreshToken: Joi.string().min(20).max(200).required(),
  }),
};

const logout = {
  body: Joi.object({
    refreshToken: Joi.string().min(20).max(200).optional(),
  }),
};

const changePassword = {
  body: Joi.object({
    currentPassword: Joi.string().min(1).max(128).required(),
    newPassword: password.invalid(Joi.ref('currentPassword')).required().messages({
      'any.invalid': 'newPassword must differ from currentPassword',
    }),
  }),
};

module.exports = { password, username, register, login, refreshToken, logout, changePassword };
