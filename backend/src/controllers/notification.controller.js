const inboxService = require('../services/notification/inbox.service');
const { sendSuccess } = require('../utils/apiResponse');

module.exports = {
  async list(req, res) {
    sendSuccess(res, { data: await inboxService.list(req.user.id, req.validated.query) });
  },
  async unreadCount(req, res) {
    sendSuccess(res, { data: await inboxService.unreadCount(req.user.id) });
  },
  async markRead(req, res) {
    sendSuccess(res, { data: await inboxService.markRead(req.user.id, req.validated.params.id) });
  },
  async markAllRead(req, res) {
    sendSuccess(res, { data: await inboxService.markAllRead(req.user.id) });
  },
  async registerDevice(req, res) {
    sendSuccess(res, {
      status: 201,
      message: 'Device registered',
      data: await inboxService.registerDevice(req.user.id, req.body),
    });
  },
  async unregisterDevice(req, res) {
    sendSuccess(res, {
      message: 'Device removed',
      data: await inboxService.unregisterDevice(req.user.id, req.validated.params.token),
    });
  },
};
