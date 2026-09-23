const AppError = require('../utils/AppError');

/**
 * Role check (doc 22, step 2). Must run after `authenticate`.
 * Accounts that must change their password can only reach auth/self routes.
 */
function authorize(...roles) {
  return (req, _res, next) => {
    if (!req.user) return next(AppError.unauthorized());
    if (req.user.mustChangePassword) {
      return next(new AppError('PASSWORD_CHANGE_REQUIRED', 'Password change required'));
    }
    if (roles.length > 0 && !roles.includes(req.user.role)) {
      return next(AppError.forbidden());
    }
    return next();
  };
}

module.exports = { authorize };
