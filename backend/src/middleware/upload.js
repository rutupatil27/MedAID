const multer = require('multer');
const env = require('../config/env');

/**
 * Single-file multipart upload held in memory (never written to disk or
 * MongoDB). Size is capped here; type is verified by content in the service.
 */
const singleDocument = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: env.uploads.maxBytes, files: 1, fields: 5 },
}).single('file');

module.exports = { singleDocument };
