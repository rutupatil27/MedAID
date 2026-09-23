const crypto = require('node:crypto');
const AppError = require('../../utils/AppError');
const logger = require('../../utils/logger');
const {
  ACCOUNT_STATUS,
  DOCUMENT_STATUS,
  ROLES,
  VERIFICATION_STATUS: V,
  VOLUNTEER_STATUS,
} = require('../../config/constants');
const { User, Volunteer } = require('../../models');
const userRepository = require('../../repositories/user.repository');
const volunteerRepository = require('../../repositories/volunteer.repository');
const documentRepository = require('../../repositories/volunteerDocument.repository');
const { getDocumentStorage } = require('../../integrations/cloudinary/documentStorage');
const { hashPassword } = require('../auth/password.service');
const tokenService = require('../auth/token.service');
const notificationService = require('../notification/notification.service');
const assignmentService = require('../assignment/assignment.service');
const emergencyAdminService = require('./emergencyAdmin.service');
const { toVolunteerView, documentView, locationView } = require('../volunteer/volunteer.mapper');

const { EVENTS } = notificationService;
const escapeRegex = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/** 12 characters with at least one letter and one digit (meets the password policy). */
function generateTemporaryPassword() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  for (;;) {
    const bytes = crypto.randomBytes(12);
    const candidate = Array.from(bytes, (b) => alphabet[b % alphabet.length]).join('');
    if (/[A-Za-z]/.test(candidate) && /\d/.test(candidate)) return candidate;
  }
}

async function findVolunteer(volunteerId) {
  const volunteer = await volunteerRepository.findById(volunteerId);
  if (!volunteer) throw AppError.notFound('Volunteer');
  return volunteer;
}

async function viewOf(volunteer) {
  const [user, documents] = await Promise.all([
    userRepository.findById(volunteer.userId),
    documentRepository.listCurrent(volunteer._id),
  ]);
  return toVolunteerView(volunteer, user, documents);
}

/**
 * Admin creates the volunteer account (D-016). The temporary password is
 * returned once and must be changed at first login (OQ-09).
 */
async function create(input, { adminUserId }) {
  const taken = await userRepository.findTakenFields(input);
  if (taken.length > 0) {
    throw new AppError('CONFLICT', 'Account already exists', {
      errors: taken.map((field) => ({ field: `body.${field}`, message: 'Already in use' })),
    });
  }
  const temporaryPassword = input.temporaryPassword || generateTemporaryPassword();
  const user = await userRepository.create({
    name: input.name,
    email: input.email,
    username: input.username,
    phone: input.phone,
    role: ROLES.VOLUNTEER,
    mustChangePassword: true,
    passwordHash: await hashPassword(temporaryPassword),
  });
  let volunteer;
  try {
    volunteer = await volunteerRepository.create({
      userId: user._id,
      createdBy: adminUserId,
      profile: input.phone ? { phone: input.phone } : {},
    });
  } catch (err) {
    await User.deleteOne({ _id: user._id }); // keep account + record consistent
    throw err;
  }
  return { volunteer: toVolunteerView(volunteer, user, []), temporaryPassword };
}

async function list({ verificationStatus, status, accountStatus, search, page, limit }) {
  const filter = {};
  if (verificationStatus) filter.verificationStatus = verificationStatus;
  if (status) filter.status = status;
  if (search || accountStatus) {
    const userFilter = { role: ROLES.VOLUNTEER };
    if (accountStatus) userFilter.accountStatus = accountStatus;
    if (search) {
      const pattern = new RegExp(escapeRegex(search), 'i');
      userFilter.$or = [{ name: pattern }, { email: pattern }, { username: pattern }];
    }
    filter.userId = { $in: await User.find(userFilter).distinct('_id') };
  }
  const [items, total] = await Promise.all([
    Volunteer.find(filter)
      .sort({ submittedAt: -1, createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .populate('userId'),
    Volunteer.countDocuments(filter),
  ]);
  return {
    items: items.map((v) => toVolunteerView(v, v.userId, [])),
    page,
    limit,
    total,
  };
}

async function get(volunteerId) {
  return viewOf(await findVolunteer(volunteerId));
}

/** Documents with short-lived signed URLs (P-12); nothing is publicly exposed. */
async function documentsWithUrls(volunteerId) {
  const volunteer = await findVolunteer(volunteerId);
  const storage = getDocumentStorage();
  const documents = await documentRepository.listCurrent(volunteer._id);
  return documents.map((doc) => {
    let url = null;
    try {
      url = storage.signedUrl(doc);
    } catch (err) {
      logger.warn({ err }, 'Could not sign document URL');
    }
    return { ...documentView(doc), url };
  });
}

async function decide(volunteerId, { approve, note, adminUserId }) {
  const now = new Date();
  const update = approve
    ? {
        $set: {
          verificationStatus: V.APPROVED,
          verifiedBy: adminUserId,
          verifiedAt: now,
          rejectionReason: null,
        },
      }
    : { $set: { verificationStatus: V.REJECTED, rejectionReason: note, verifiedAt: null } };

  const volunteer = await volunteerRepository.updateById(volunteerId, update, {
    where: { verificationStatus: V.PENDING },
  });
  if (!volunteer) {
    await findVolunteer(volunteerId);
    throw AppError.conflict('Only volunteers awaiting review can be verified or rejected');
  }
  await documentRepository.reviewPending(volunteer._id, {
    status: approve ? DOCUMENT_STATUS.APPROVED : DOCUMENT_STATUS.REJECTED,
    reviewedBy: adminUserId,
    reviewNote: note,
  });
  await notificationService.notify({
    type: approve ? EVENTS.VERIFICATION_APPROVED : EVENTS.VERIFICATION_REJECTED,
    recipients: [volunteer.userId],
    data: { volunteerId: volunteer.id },
  });
  return viewOf(volunteer);
}

const verify = (volunteerId, { note, adminUserId }) =>
  decide(volunteerId, { approve: true, note, adminUserId });

const reject = (volunteerId, { reason, adminUserId }) =>
  decide(volunteerId, { approve: false, note: reason, adminUserId });

/**
 * Suspends or reactivates a volunteer's account. A suspended volunteer is
 * taken offline, signed out everywhere, and any emergency they hold goes back
 * to the engine so nobody is left waiting.
 */
async function setAccountStatus(volunteerId, { accountStatus, adminUserId }) {
  const volunteer = await findVolunteer(volunteerId);
  const now = new Date();
  await User.updateOne(
    { _id: volunteer.userId },
    accountStatus === ACCOUNT_STATUS.SUSPENDED
      ? { $set: { accountStatus, suspendedAt: now, suspendedBy: adminUserId } }
      : { $set: { accountStatus }, $unset: { suspendedAt: '', suspendedBy: '' } },
  );

  if (accountStatus === ACCOUNT_STATUS.SUSPENDED) {
    await tokenService.revokeAllForUser(volunteer.userId);
    if (volunteer.currentEmergencyId) {
      await emergencyAdminService.releaseForReassignment(volunteer.currentEmergencyId, {
        adminUserId,
        reason: 'VOLUNTEER_SUSPENDED',
      });
      assignmentService.requestAssignment(volunteer.currentEmergencyId);
    }
    await volunteerRepository.updateById(volunteer._id, {
      $set: { status: VOLUNTEER_STATUS.OFFLINE, statusChangedAt: now },
      $unset: { currentLocation: '', locationAccuracy: '', locationUpdatedAt: '' },
    });
    await notificationService.notify({
      type: EVENTS.ACCOUNT_SUSPENDED,
      recipients: [volunteer.userId],
      data: { volunteerId: volunteer.id },
    });
  }
  return get(volunteerId);
}

/** Live positions of ACTIVE/BUSY volunteers (admin only, doc 18 privacy). */
async function locations() {
  const volunteers = await Volunteer.find({
    status: { $in: [VOLUNTEER_STATUS.ACTIVE, VOLUNTEER_STATUS.BUSY] },
    currentLocation: { $exists: true },
  }).populate('userId', 'name');
  return volunteers.map((v) => ({
    volunteerId: v.id,
    name: v.userId?.name ?? null,
    status: v.status,
    currentEmergencyId: v.currentEmergencyId?.toString() ?? null,
    location: locationView(v),
  }));
}

module.exports = {
  generateTemporaryPassword,
  create,
  list,
  get,
  documentsWithUrls,
  verify,
  reject,
  setAccountStatus,
  locations,
};
