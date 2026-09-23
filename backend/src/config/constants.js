/**
 * Domain enums shared by models, services and validators.
 * Values are language-neutral and part of the API contract.
 */

const freeze = (values) => Object.freeze(Object.fromEntries(values.map((v) => [v, v])));

const ROLES = freeze(['USER', 'VOLUNTEER', 'ADMIN']);

/** Applies to every account (P-02). */
const ACCOUNT_STATUS = freeze(['ACTIVE', 'SUSPENDED']);

/** Volunteer verification lifecycle (P-02, doc 20). */
const VERIFICATION_STATUS = freeze(['NOT_SUBMITTED', 'PENDING', 'APPROVED', 'REJECTED']);

/** Volunteer operational availability (P-02). */
const VOLUNTEER_STATUS = freeze(['OFFLINE', 'ACTIVE', 'BUSY']);

/** Emergency lifecycle (doc 03). */
const EMERGENCY_STATUS = freeze([
  'CREATED',
  'ASSIGNING',
  'ASSIGNED',
  'ACCEPTED',
  'IN_PROGRESS',
  'RESOLVED',
  'CANCELLED',
  'EXPIRED',
  'UNASSIGNED',
]);

const TERMINAL_EMERGENCY_STATUSES = Object.freeze([
  EMERGENCY_STATUS.RESOLVED,
  EMERGENCY_STATUS.CANCELLED,
  EMERGENCY_STATUS.EXPIRED,
]);

const OPEN_EMERGENCY_STATUSES = Object.freeze(
  Object.values(EMERGENCY_STATUS).filter((s) => !TERMINAL_EMERGENCY_STATUSES.includes(s)),
);

/** Per-attempt assignment lifecycle. */
const ASSIGNMENT_STATUS = freeze([
  'PENDING',
  'ACCEPTED',
  'DECLINED',
  'EXPIRED',
  'CANCELLED',
  'COMPLETED',
]);

const ACTIVE_ASSIGNMENT_STATUSES = Object.freeze([
  ASSIGNMENT_STATUS.PENDING,
  ASSIGNMENT_STATUS.ACCEPTED,
]);

const DISTANCE_SOURCE = freeze(['ROUTING', 'FALLBACK']);

/** Required volunteer documents (OQ-20 default). */
const DOCUMENT_TYPES = freeze(['ID_PROOF', 'FIRST_AID_CERTIFICATE', 'OTHER']);
const REQUIRED_DOCUMENT_TYPES = Object.freeze([
  DOCUMENT_TYPES.ID_PROOF,
  DOCUMENT_TYPES.FIRST_AID_CERTIFICATE,
]);
const DOCUMENT_STATUS = freeze(['PENDING', 'APPROVED', 'REJECTED', 'REPLACED']);
const ALLOWED_DOCUMENT_MIME_TYPES = Object.freeze(['application/pdf', 'image/jpeg', 'image/png']);

const LANGUAGES = Object.freeze(['en', 'hi', 'mr']);

const GENDERS = freeze(['MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY']);
const BLOOD_GROUPS = Object.freeze(['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'UNKNOWN']);

const HOSPITAL_SOURCES = freeze(['DEMO_SEED', 'OSM', 'MANUAL']);

/** Local time zone for human-readable identifiers (alert numbers). */
const APP_TIMEZONE = 'Asia/Kolkata';

module.exports = {
  ROLES,
  ACCOUNT_STATUS,
  VERIFICATION_STATUS,
  VOLUNTEER_STATUS,
  EMERGENCY_STATUS,
  TERMINAL_EMERGENCY_STATUSES,
  OPEN_EMERGENCY_STATUSES,
  ASSIGNMENT_STATUS,
  ACTIVE_ASSIGNMENT_STATUSES,
  DISTANCE_SOURCE,
  DOCUMENT_TYPES,
  REQUIRED_DOCUMENT_TYPES,
  DOCUMENT_STATUS,
  ALLOWED_DOCUMENT_MIME_TYPES,
  LANGUAGES,
  GENDERS,
  BLOOD_GROUPS,
  HOSPITAL_SOURCES,
  APP_TIMEZONE,
};
