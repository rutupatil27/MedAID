const Joi = require('joi');
const { idParams, pagination } = require('./common.validator');

const list = {
  query: Joi.object({ ...pagination, unreadOnly: Joi.boolean().default(false) }),
};

const byId = { params: idParams };

// FCM registration tokens are long, URL-safe strings that may contain ':'.
const token = Joi.string()
  .trim()
  .min(20)
  .max(4096)
  .pattern(/^[A-Za-z0-9:_-]+$/);

const registerDevice = {
  body: Joi.object({
    token: token.required(),
    platform: Joi.string().valid('android', 'ios', 'web').required(),
  }),
};

const unregisterDevice = { params: Joi.object({ token: token.required() }) };

module.exports = { list, byId, registerDevice, unregisterDevice };
