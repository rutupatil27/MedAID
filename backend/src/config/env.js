const path = require('node:path');
const dotenv = require('dotenv');
const Joi = require('joi');

// Existing process.env values win over .env (tests and deployments set them directly).
dotenv.config({ path: path.resolve(__dirname, '../../.env'), quiet: true });

const schema = Joi.object({
  NODE_ENV: Joi.string().valid('development', 'test', 'production').default('development'),
  PORT: Joi.number().port().default(5000),
  LOG_LEVEL: Joi.string()
    .valid('fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent')
    .default('info'),
  CORS_ORIGINS: Joi.string().allow('').default(''),
  TRUST_PROXY: Joi.number().integer().min(0).default(0),

  MONGODB_URI: Joi.string()
    .uri({ scheme: ['mongodb', 'mongodb+srv'] })
    .required(),

  JWT_ACCESS_SECRET: Joi.string().min(32).required(),
  JWT_ACCESS_EXPIRES_IN: Joi.string().default('15m'),
  REFRESH_TOKEN_TTL_DAYS: Joi.number().integer().min(1).max(90).default(7),
  BCRYPT_SALT_ROUNDS: Joi.number().integer().min(4).max(15).default(12),

  RATE_LIMIT_WINDOW_MS: Joi.number().integer().min(1000).default(900000),
  RATE_LIMIT_MAX: Joi.number().integer().min(1).default(600),
  AUTH_RATE_LIMIT_MAX: Joi.number().integer().min(1).default(30),

  CLOUDINARY_CLOUD_NAME: Joi.string().allow('').default(''),
  CLOUDINARY_API_KEY: Joi.string().allow('').default(''),
  CLOUDINARY_API_SECRET: Joi.string().allow('').default(''),
  CLOUDINARY_FOLDER: Joi.string().default('medaid/volunteer-documents'),
  MAX_UPLOAD_MB: Joi.number().min(1).max(20).default(5),
  DOCUMENT_URL_TTL_SECONDS: Joi.number().integer().min(30).max(3600).default(300),

  ORS_API_KEY: Joi.string().allow('').default(''),
  OSM_HOSPITAL_SYNC: Joi.boolean().default(true),
  // Comma-separated: tried in order, because public mirrors are often busy.
  OSM_OVERPASS_URL: Joi.string().default(
    'https://overpass-api.de/api/interpreter,https://overpass.kumi.systems/api/interpreter,https://overpass.private.coffee/api/interpreter',
  ),
  OSM_TIMEOUT_MS: Joi.number().integer().min(1000).max(60000).default(25000),
  OSM_CACHE_HOURS: Joi.number().integer().min(1).max(720).default(24),
  OSM_MAX_RESULTS: Joi.number().integer().min(1).max(500).default(150),
  ORS_BASE_URL: Joi.string().uri().default('https://api.openrouteservice.org'),
  ORS_PROFILE: Joi.string()
    .valid('foot-walking', 'driving-car', 'cycling-regular')
    .default('foot-walking'),
  ROUTING_TIMEOUT_MS: Joi.number().integer().min(500).default(4000),

  ASSIGNMENT_ACCEPT_TIMEOUT_SECONDS: Joi.number().integer().min(10).default(120),
  ASSIGNMENT_EXPIRY_WARNING_SECONDS: Joi.number().integer().min(0).default(30),
  LOCATION_STALE_SECONDS: Joi.number().integer().min(30).default(300),
  ASSIGNMENT_SEARCH_RADIUS_METERS: Joi.number().integer().min(100).default(5000),
  ASSIGNMENT_MAX_CANDIDATES: Joi.number().integer().min(1).max(25).default(10),
  ASSIGNMENT_SCAN_INTERVAL_MS: Joi.number().integer().min(1000).default(10000),
  UNASSIGNED_RETRY_INTERVAL_MS: Joi.number().integer().min(1000).default(30000),
  ASSIGNMENT_ADMIN_ALERT_AFTER_ATTEMPTS: Joi.number().integer().min(1).default(3),
  JOBS_ENABLED: Joi.boolean().default(true),

  FCM_SERVICE_ACCOUNT_PATH: Joi.string().allow('').default(''),
}).unknown(true);

const { value, error } = schema.validate(process.env, { abortEarly: false, convert: true });

if (error) {
  const details = error.details.map((d) => d.message).join('; ');
  throw new Error(`Invalid environment configuration: ${details}`);
}

const env = Object.freeze({
  nodeEnv: value.NODE_ENV,
  isProduction: value.NODE_ENV === 'production',
  isTest: value.NODE_ENV === 'test',
  port: value.PORT,
  logLevel: value.NODE_ENV === 'test' ? 'silent' : value.LOG_LEVEL,
  corsOrigins: value.CORS_ORIGINS.split(',')
    .map((o) => o.trim())
    .filter(Boolean),
  trustProxy: value.TRUST_PROXY,
  mongodbUri: value.MONGODB_URI,
  auth: Object.freeze({
    accessSecret: value.JWT_ACCESS_SECRET,
    accessExpiresIn: value.JWT_ACCESS_EXPIRES_IN,
    refreshTokenTtlDays: value.REFRESH_TOKEN_TTL_DAYS,
    bcryptSaltRounds: value.BCRYPT_SALT_ROUNDS,
  }),
  rateLimit: Object.freeze({
    windowMs: value.RATE_LIMIT_WINDOW_MS,
    max: value.RATE_LIMIT_MAX,
    authMax: value.AUTH_RATE_LIMIT_MAX,
  }),
  cloudinary: Object.freeze({
    cloudName: value.CLOUDINARY_CLOUD_NAME,
    apiKey: value.CLOUDINARY_API_KEY,
    apiSecret: value.CLOUDINARY_API_SECRET,
    folder: value.CLOUDINARY_FOLDER,
    isConfigured: Boolean(
      value.CLOUDINARY_CLOUD_NAME && value.CLOUDINARY_API_KEY && value.CLOUDINARY_API_SECRET,
    ),
  }),
  uploads: Object.freeze({
    maxBytes: Math.round(value.MAX_UPLOAD_MB * 1024 * 1024),
    documentUrlTtlSeconds: value.DOCUMENT_URL_TTL_SECONDS,
  }),
  osm: Object.freeze({
    enabled: value.OSM_HOSPITAL_SYNC,
    overpassUrl: value.OSM_OVERPASS_URL,
    timeoutMs: value.OSM_TIMEOUT_MS,
    cacheHours: value.OSM_CACHE_HOURS,
    maxResults: value.OSM_MAX_RESULTS,
  }),
  routing: Object.freeze({
    orsApiKey: value.ORS_API_KEY,
    orsBaseUrl: value.ORS_BASE_URL,
    profile: value.ORS_PROFILE,
    timeoutMs: value.ROUTING_TIMEOUT_MS,
  }),
  assignment: Object.freeze({
    acceptTimeoutMs: value.ASSIGNMENT_ACCEPT_TIMEOUT_SECONDS * 1000,
    expiryWarningMs: value.ASSIGNMENT_EXPIRY_WARNING_SECONDS * 1000,
    locationStaleMs: value.LOCATION_STALE_SECONDS * 1000,
    searchRadiusMeters: value.ASSIGNMENT_SEARCH_RADIUS_METERS,
    maxCandidates: value.ASSIGNMENT_MAX_CANDIDATES,
    scanIntervalMs: value.ASSIGNMENT_SCAN_INTERVAL_MS,
    unassignedRetryIntervalMs: value.UNASSIGNED_RETRY_INTERVAL_MS,
    adminAlertAfterAttempts: value.ASSIGNMENT_ADMIN_ALERT_AFTER_ATTEMPTS,
  }),
  jobsEnabled: value.JOBS_ENABLED,
  fcm: Object.freeze({ serviceAccountPath: value.FCM_SERVICE_ACCOUNT_PATH }),
});

module.exports = env;
