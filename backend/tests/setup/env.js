// Runs in every test worker before any module is loaded.
process.env.NODE_ENV = 'test';
process.env.JWT_ACCESS_SECRET = 'test-access-secret-that-is-long-enough-1234567890';
process.env.BCRYPT_SALT_ROUNDS = '4';
process.env.RATE_LIMIT_MAX = '100000';
process.env.AUTH_RATE_LIMIT_MAX = '100000';
process.env.JOBS_ENABLED = 'false';
process.env.CORS_ORIGINS = 'http://localhost:3000';
process.env.CLOUDINARY_CLOUD_NAME = '';
process.env.ORS_API_KEY = '';
// Tests never call the public Overpass service; they inject a fake directory.
process.env.OSM_HOSPITAL_SYNC = 'false';
process.env.FCM_SERVICE_ACCOUNT_PATH = '';
// MONGODB_URI is provided by globalSetup (in-memory replica set).
