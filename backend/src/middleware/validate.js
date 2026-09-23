const AppError = require('../utils/AppError');

const JOI_OPTIONS = { abortEarly: false, stripUnknown: true, convert: true };

/**
 * Validates request parts against Joi schemas.
 * Sanitized values are exposed on `req.validated` (Express 5 makes `req.query`
 * read-only), and `req.body` is replaced with the sanitized body.
 *
 * @param {{ body?: import('joi').Schema, query?: import('joi').Schema, params?: import('joi').Schema }} schemas
 */
function validate(schemas) {
  return (req, _res, next) => {
    const validated = {};
    const errors = [];

    for (const part of ['params', 'query', 'body']) {
      const schema = schemas[part];
      if (!schema) continue;
      const { value, error } = schema.validate(req[part] ?? {}, JOI_OPTIONS);
      if (error) {
        for (const detail of error.details) {
          errors.push({ field: [part, ...detail.path].join('.'), message: detail.message });
        }
      } else {
        validated[part] = value;
      }
    }

    if (errors.length > 0) return next(AppError.validation(errors));

    req.validated = validated;
    if (validated.body) req.body = validated.body;
    return next();
  };
}

module.exports = { validate };
