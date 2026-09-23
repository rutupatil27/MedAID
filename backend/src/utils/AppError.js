const { ERROR_CODES } = require('./errorCodes');

/** Operational error that maps directly onto the standard error envelope. */
class AppError extends Error {
  /**
   * @param {keyof ERROR_CODES} code
   * @param {string} message developer-facing message (clients localize by code)
   * @param {{ status?: number, errors?: Array<{field: string, message: string}> }} [options]
   */
  constructor(code, message, { status, errors = [] } = {}) {
    super(message);
    this.name = 'AppError';
    this.code = ERROR_CODES[code] ? code : 'INTERNAL_ERROR';
    this.status = status ?? ERROR_CODES[this.code];
    this.errors = errors;
    this.isOperational = true;
  }

  static validation(errors, message = 'Validation failed') {
    return new AppError('VALIDATION_ERROR', message, { errors });
  }

  static notFound(resource = 'Resource') {
    return new AppError('NOT_FOUND', `${resource} not found`);
  }

  static unauthorized(message = 'Authentication required') {
    return new AppError('AUTH_UNAUTHORIZED', message);
  }

  static forbidden(message = 'You do not have permission to perform this action') {
    return new AppError('FORBIDDEN', message);
  }

  static conflict(message = 'Request conflicts with the current state', code = 'CONFLICT') {
    return new AppError(code, message);
  }
}

module.exports = AppError;
