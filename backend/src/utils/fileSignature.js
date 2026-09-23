/**
 * Detects a file type from its leading bytes ("magic numbers"). Uploads are
 * judged by content, never by filename extension or the client's declared
 * MIME type (doc 20).
 */
const SIGNATURES = [
  { mimeType: 'application/pdf', bytes: [0x25, 0x50, 0x44, 0x46, 0x2d] }, // %PDF-
  { mimeType: 'image/png', bytes: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a] },
  { mimeType: 'image/jpeg', bytes: [0xff, 0xd8, 0xff] },
];

/** @returns {string|null} detected MIME type, or null if unrecognised */
function detectMimeType(buffer) {
  if (!Buffer.isBuffer(buffer)) return null;
  const match = SIGNATURES.find(({ bytes }) => bytes.every((byte, i) => buffer[i] === byte));
  return match ? match.mimeType : null;
}

module.exports = { detectMimeType };
