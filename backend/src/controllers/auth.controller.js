const authService = require('../services/auth/auth.service');
const { sendSuccess } = require('../utils/apiResponse');

const context = (req) => ({ userAgent: req.get('user-agent') });

async function register(req, res) {
  const session = await authService.register(req.body, context(req));
  sendSuccess(res, { status: 201, message: 'Account created', data: session });
}

async function login(req, res) {
  const session = await authService.login(req.body, context(req));
  sendSuccess(res, { message: 'Logged in', data: session });
}

async function refresh(req, res) {
  const session = await authService.refresh(req.body.refreshToken, context(req));
  sendSuccess(res, { message: 'Session refreshed', data: session });
}

async function logout(req, res) {
  await authService.logout(req.body.refreshToken);
  sendSuccess(res, { message: 'Logged out' });
}

async function changePassword(req, res) {
  const session = await authService.changePassword(req.user.id, req.body, context(req));
  sendSuccess(res, { message: 'Password changed', data: session });
}

module.exports = { register, login, refresh, logout, changePassword };
