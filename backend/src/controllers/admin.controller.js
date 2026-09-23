const volunteerAdmin = require('../services/admin/volunteerAdmin.service');
const emergencyAdmin = require('../services/admin/emergencyAdmin.service');
const dashboardService = require('../services/admin/dashboard.service');
const reportService = require('../services/admin/report.service');
const campService = require('../services/camp/camp.service');
const userService = require('../services/user/user.service');
const inboxService = require('../services/notification/inbox.service');
const { EMERGENCY_STATUS } = require('../config/constants');
const { sendSuccess } = require('../utils/apiResponse');

const admin = (req) => ({ adminUserId: req.user.id });
const id = (req) => req.validated.params.id;

module.exports = {
  // Dashboard & reports
  async dashboard(_req, res) {
    sendSuccess(res, { data: await dashboardService.getDashboard() });
  },
  async report(req, res) {
    sendSuccess(res, { data: await reportService.summary(req.validated.query) });
  },

  // Volunteers
  async createVolunteer(req, res) {
    sendSuccess(res, {
      status: 201,
      message: 'Volunteer created',
      data: await volunteerAdmin.create(req.body, admin(req)),
    });
  },
  async listVolunteers(req, res) {
    sendSuccess(res, { data: await volunteerAdmin.list(req.validated.query) });
  },
  async volunteerLocations(_req, res) {
    sendSuccess(res, { data: await volunteerAdmin.locations() });
  },
  async getVolunteer(req, res) {
    sendSuccess(res, { data: await volunteerAdmin.get(id(req)) });
  },
  async volunteerDocuments(req, res) {
    sendSuccess(res, { data: await volunteerAdmin.documentsWithUrls(id(req)) });
  },
  async verifyVolunteer(req, res) {
    sendSuccess(res, {
      message: 'Volunteer verified',
      data: await volunteerAdmin.verify(id(req), { note: req.body.note, ...admin(req) }),
    });
  },
  async rejectVolunteer(req, res) {
    sendSuccess(res, {
      message: 'Volunteer rejected',
      data: await volunteerAdmin.reject(id(req), { reason: req.body.reason, ...admin(req) }),
    });
  },
  async setVolunteerStatus(req, res) {
    sendSuccess(res, {
      message: 'Account status updated',
      data: await volunteerAdmin.setAccountStatus(id(req), { ...req.body, ...admin(req) }),
    });
  },

  // Emergencies
  async listEmergencies(req, res) {
    sendSuccess(res, { data: await emergencyAdmin.list(req.validated.query) });
  },
  async getEmergency(req, res) {
    sendSuccess(res, { data: await emergencyAdmin.get(id(req)) });
  },
  async emergencyAssignments(req, res) {
    sendSuccess(res, { data: await emergencyAdmin.listAssignments(id(req)) });
  },
  async reassignEmergency(req, res) {
    sendSuccess(res, {
      message: 'Emergency reassigned',
      data: await emergencyAdmin.reassign(id(req), { ...req.body, ...admin(req) }),
    });
  },
  async resolveEmergency(req, res) {
    sendSuccess(res, {
      message: 'Emergency resolved',
      data: await emergencyAdmin.close(id(req), {
        to: EMERGENCY_STATUS.RESOLVED,
        note: req.body.note,
        ...admin(req),
      }),
    });
  },
  async cancelEmergency(req, res) {
    sendSuccess(res, {
      message: 'Emergency cancelled',
      data: await emergencyAdmin.close(id(req), {
        to: EMERGENCY_STATUS.CANCELLED,
        note: req.body.note,
        ...admin(req),
      }),
    });
  },

  // Medical camps
  async createCamp(req, res) {
    sendSuccess(res, {
      status: 201,
      message: 'Camp created',
      data: await campService.create(req.body, admin(req)),
    });
  },
  async listCamps(req, res) {
    sendSuccess(res, { data: await campService.list(req.validated.query) });
  },
  async getCamp(req, res) {
    sendSuccess(res, { data: await campService.get(id(req)) });
  },
  async updateCamp(req, res) {
    sendSuccess(res, {
      message: 'Camp updated',
      data: await campService.update(id(req), req.body, admin(req)),
    });
  },
  async deleteCamp(req, res) {
    await campService.remove(id(req), admin(req));
    sendSuccess(res, { message: 'Camp deleted' });
  },

  // Notices
  async sendNotice(req, res) {
    sendSuccess(res, {
      status: 201,
      message: 'Notice sent',
      data: await inboxService.sendVolunteerNotice(req.body.message),
    });
  },

  // Users
  async listUsers(req, res) {
    sendSuccess(res, { data: await userService.listUsers(req.validated.query) });
  },
  async setUserStatus(req, res) {
    sendSuccess(res, {
      message: 'Account status updated',
      data: await userService.setAccountStatus(id(req), { ...req.body, ...admin(req) }),
    });
  },
};
