const AppError = require('../utils/AppError');

function notFound(req, _res, next) {
  next(new AppError('NOT_FOUND', `Route ${req.method} ${req.originalUrl} not found`));
}

module.exports = { notFound };
