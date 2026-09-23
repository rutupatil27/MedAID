const Joi = require('joi');
const {
  ACCOUNT_STATUS,
  EMERGENCY_STATUS,
  ROLES,
  VERIFICATION_STATUS,
  VOLUNTEER_STATUS,
} = require('../config/constants');
const {
  idParams,
  latitude,
  longitude,
  objectId,
  pagination,
  phone,
} = require('./common.validator');
const { password, username } = require('./auth.validator');

const search = Joi.string().trim().max(100).allow('');

const createVolunteer = {
  body: Joi.object({
    name: Joi.string().trim().min(2).max(100).required(),
    email: Joi.string().trim().lowercase().email().max(254).required(),
    username: username.required(),
    phone: phone.allow(''),
    temporaryPassword: password,
  }),
};

const listVolunteers = {
  query: Joi.object({
    ...pagination,
    verificationStatus: Joi.string().valid(...Object.values(VERIFICATION_STATUS)),
    status: Joi.string().valid(...Object.values(VOLUNTEER_STATUS)),
    accountStatus: Joi.string().valid(...Object.values(ACCOUNT_STATUS)),
    search,
  }),
};

const byId = { params: idParams };

const verify = {
  params: idParams,
  body: Joi.object({ note: Joi.string().trim().max(500).allow('') }),
};

const reject = {
  params: idParams,
  body: Joi.object({ reason: Joi.string().trim().min(3).max(500).required() }),
};

const accountStatus = {
  params: idParams,
  body: Joi.object({
    accountStatus: Joi.string()
      .valid(...Object.values(ACCOUNT_STATUS))
      .required(),
  }),
};

const listEmergencies = {
  query: Joi.object({
    ...pagination,
    status: Joi.string().valid(...Object.values(EMERGENCY_STATUS)),
    open: Joi.boolean(),
    search,
  }),
};

const reassign = { params: idParams, body: Joi.object({ volunteerId: objectId }) };

const closeEmergency = {
  params: idParams,
  body: Joi.object({ note: Joi.string().trim().min(3).max(1000).required() }),
};

const campFields = {
  name: Joi.string().trim().min(2).max(120),
  description: Joi.string().trim().max(1000).allow(''),
  latitude,
  longitude,
  address: Joi.string().trim().max(300),
  services: Joi.array().items(Joi.string().trim().max(80)).max(30),
  contact: Joi.object({
    name: Joi.string().trim().max(100).allow(''),
    phone: phone.allow(''),
  }),
  startDateTime: Joi.date().iso(),
  endDateTime: Joi.date().iso(),
  isActive: Joi.boolean(),
};

const createCamp = {
  body: Joi.object({
    ...campFields,
    name: campFields.name.required(),
    latitude: latitude.required(),
    longitude: longitude.required(),
    address: campFields.address.required(),
    startDateTime: campFields.startDateTime.required(),
    endDateTime: campFields.endDateTime.greater(Joi.ref('startDateTime')).required(),
  }),
};

const updateCamp = {
  params: idParams,
  body: Joi.object(campFields).and('latitude', 'longitude').min(1),
};

const listCamps = {
  query: Joi.object({
    ...pagination,
    status: Joi.string()
      .valid('ALL', 'ACTIVE_NOW', 'UPCOMING', 'EXPIRED', 'INACTIVE')
      .default('ALL'),
    search,
  }),
};

const listUsers = {
  query: Joi.object({
    ...pagination,
    role: Joi.string().valid(...Object.values(ROLES)),
    accountStatus: Joi.string().valid(...Object.values(ACCOUNT_STATUS)),
    search,
  }),
};

const report = {
  query: Joi.object({ from: Joi.date().iso(), to: Joi.date().iso().min(Joi.ref('from')) }),
};

const notice = {
  body: Joi.object({ message: Joi.string().trim().min(3).max(300).required() }),
};

module.exports = {
  notice,
  createVolunteer,
  listVolunteers,
  byId,
  verify,
  reject,
  accountStatus,
  listEmergencies,
  reassign,
  closeEmergency,
  createCamp,
  updateCamp,
  listCamps,
  listUsers,
  report,
};
