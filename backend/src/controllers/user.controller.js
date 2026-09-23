const userService = require('../services/user/user.service');
const { sendSuccess } = require('../utils/apiResponse');

async function getMe(req, res) {
  const user = await userService.getMe(req.user.id);
  sendSuccess(res, { data: user });
}

async function updateMe(req, res) {
  const user = await userService.updateMe(req.user.id, req.user.role, req.body);
  sendSuccess(res, { message: 'Profile updated', data: user });
}

module.exports = { getMe, updateMe };
