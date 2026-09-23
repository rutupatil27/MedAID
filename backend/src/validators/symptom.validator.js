const Joi = require('joi');
const { symptomKeys } = require('../services/symptom/symptom.service');

const check = {
  body: Joi.object({
    symptoms: Joi.array()
      .items(Joi.string().valid(...symptomKeys))
      .min(1)
      .max(15)
      .unique()
      .required(),
    ageGroup: Joi.string().valid('YOUNG_CHILD', 'CHILD', 'ADULT', 'OLDER_ADULT').default('ADULT'),
    pregnant: Joi.boolean().default(false),
    durationDays: Joi.number().integer().min(0).max(365).default(0),
  }),
};

module.exports = { check };
