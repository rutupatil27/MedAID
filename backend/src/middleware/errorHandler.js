const mongoose = require('mongoose');
const multer = require('multer');
const AppError = require('../utils/AppError');
const logger = require('../utils/logger');
const { sendError } = require('../utils/apiResponse');

/** Converts known library errors into AppErrors. */
function normalize(err) {
  if (err instanceof AppError) return err;

  if (err?.type === 'entity.parse.failed') {
    return AppError.validation([], 'Malformed JSON body');
  }
  if (err?.type === 'entity.too.large') {
    return new AppError('VALIDATION_ERROR', 'Request body too large', { status: 413 });
  }
  if (err instanceof multer.MulterError) {
    const status = err.code === 'LIMIT_FILE_SIZE' ? 413 : 422;
    return new AppError('FILE_UPLOAD_FAILED', err.message, { status });
  }
  if (err instanceof mongoose.Error.ValidationError) {
    const errors = Object.values(err.errors).map((e) => ({ field: e.path, message: e.message }));
    return AppError.validation(errors);
  }
  if (err instanceof mongoose.Error.CastError) {
    return AppError.validation([{ field: err.path, message: 'Invalid value' }]);
  }
  if (err?.code === 11000) {
    const fields = Object.keys(err.keyPattern ?? err.keyValue ?? {});
    return new AppError('CONFLICT', 'Duplicate value', {
      errors: fields.map((field) => ({ field, message: 'Already exists' })),
    });
  }
  return null;
}

// Express recognizes error handlers by their 4-argument signature.
function errorHandler(err, req, res, _next) {
  const appError = normalize(err);

  if (!appError) {
    logger.error({ err, path: req.originalUrl, method: req.method }, 'Unhandled error');
    return sendError(res, {
      status: 500,
      code: 'INTERNAL_ERROR',
      message: 'Internal server error',
    });
  }

  if (appError.status >= 500) {
    logger.error({ err, path: req.originalUrl }, appError.message);
  }

  return sendError(res, {
    status: appError.status,
    code: appError.code,
    message: appError.message,
    errors: appError.errors,
  });
}

module.exports = { errorHandler };
