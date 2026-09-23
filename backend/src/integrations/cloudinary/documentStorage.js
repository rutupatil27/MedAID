const cloudinary = require('cloudinary').v2;
const env = require('../../config/env');
const AppError = require('../../utils/AppError');

/**
 * Volunteer document storage (D-011, P-12).
 *
 * Interface:
 *   upload({ buffer, mimeType, publicIdHint }) -> { publicId, resourceType, format, deliveryType }
 *   signedUrl({ publicId, resourceType, format }) -> short-lived URL string
 *   remove({ publicId, resourceType }) -> void
 *
 * Files use Cloudinary "authenticated" delivery, so they are only reachable
 * through URLs signed by this backend. Secrets never leave the server.
 */
function createCloudinaryStorage(config = env.cloudinary) {
  cloudinary.config({
    cloud_name: config.cloudName,
    api_key: config.apiKey,
    api_secret: config.apiSecret,
    secure: true,
  });

  const resourceTypeFor = (mimeType) => (mimeType === 'application/pdf' ? 'raw' : 'image');

  return {
    async upload({ buffer, mimeType, publicIdHint }) {
      const resourceType = resourceTypeFor(mimeType);
      const result = await new Promise((resolve, reject) => {
        cloudinary.uploader
          .upload_stream(
            {
              folder: config.folder,
              public_id: publicIdHint,
              resource_type: resourceType,
              type: 'authenticated',
              overwrite: false,
            },
            (error, uploaded) => (error ? reject(error) : resolve(uploaded)),
          )
          .end(buffer);
      });
      return {
        publicId: result.public_id,
        resourceType,
        format: result.format ?? (mimeType === 'application/pdf' ? 'pdf' : undefined),
        deliveryType: 'authenticated',
      };
    },

    signedUrl({ publicId, resourceType, format }) {
      return cloudinary.utils.private_download_url(publicId, format ?? '', {
        resource_type: resourceType,
        type: 'authenticated',
        expires_at: Math.floor(Date.now() / 1000) + env.uploads.documentUrlTtlSeconds,
      });
    },

    async remove({ publicId, resourceType }) {
      await cloudinary.uploader.destroy(publicId, {
        resource_type: resourceType,
        type: 'authenticated',
        invalidate: true,
      });
    },
  };
}

/** Used when Cloudinary credentials are missing: fails clearly, stores nothing. */
const unconfiguredStorage = {
  async upload() {
    throw new AppError('FILE_UPLOAD_FAILED', 'Document storage is not configured', {
      status: 503,
    });
  },
  signedUrl() {
    throw new AppError('FILE_UPLOAD_FAILED', 'Document storage is not configured', {
      status: 503,
    });
  },
  async remove() {},
};

let storage = null;

function getDocumentStorage() {
  storage ??= env.cloudinary.isConfigured ? createCloudinaryStorage() : unconfiguredStorage;
  return storage;
}

/** Test seam: replace the storage provider. */
function setDocumentStorage(replacement) {
  storage = replacement;
}

module.exports = { getDocumentStorage, setDocumentStorage, createCloudinaryStorage };
