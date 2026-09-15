const cloudinary = require('cloudinary').v2;
require('dotenv').config();

// Configure Cloudinary SDK
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'demo',
  api_key: process.env.CLOUDINARY_API_KEY || 'demo',
  api_secret: process.env.CLOUDINARY_API_SECRET || 'demo',
  secure: true,
});

/**
 * Standard Folder Paths for Cloudinary Storage
 */
const CLOUDINARY_FOLDERS = {
  EXCEL_SHEETS: 'mcq-portal/excel-sheets',
  PROFILES: 'mcq-portal/profiles',
  RESULTS: 'mcq-portal/results',
  QUESTION_IMAGES: 'mcq-portal/question-images',
  REPORTS: 'mcq-portal/reports',
};

/**
 * Upload buffer stream to Cloudinary
 * @param {Buffer} buffer - File buffer
 * @param {Object} options - Upload options (folder, resource_type, public_id, etc.)
 */
const uploadBuffer = (buffer, options = {}) => {
  return new Promise((resolve, reject) => {
    // If mock/demo credentials, provide simulation fallback
    if (!process.env.CLOUDINARY_API_KEY || process.env.CLOUDINARY_API_KEY === 'demo' || process.env.CLOUDINARY_API_KEY === 'your_cloudinary_api_key') {
      const simulatedId = `${options.folder || 'mcq-portal'}/demo_${Date.now()}`;
      return resolve({
        public_id: simulatedId,
        secure_url: `https://res.cloudinary.com/demo/image/upload/sample.jpg`,
        url: `http://res.cloudinary.com/demo/image/upload/sample.jpg`,
        bytes: buffer.length,
        format: options.format || 'bin',
        resource_type: options.resource_type || 'auto',
        is_mock: true,
      });
    }

    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder: options.folder || CLOUDINARY_FOLDERS.EXCEL_SHEETS,
        resource_type: options.resource_type || 'auto',
        public_id: options.public_id,
        use_filename: true,
        unique_filename: true,
        ...options,
      },
      (error, result) => {
        if (error) {
          console.error('[Cloudinary Upload Error]', error);
          return reject(error);
        }
        resolve(result);
      }
    );

    uploadStream.end(buffer);
  });
};

/**
 * Delete a resource from Cloudinary
 * @param {string} publicId - Cloudinary Public ID
 * @param {string} resourceType - 'image' | 'raw' | 'video'
 */
const deleteResource = async (publicId, resourceType = 'image') => {
  try {
    if (!process.env.CLOUDINARY_API_KEY || process.env.CLOUDINARY_API_KEY === 'demo' || process.env.CLOUDINARY_API_KEY === 'your_cloudinary_api_key') {
      console.log(`[Cloudinary Mock] Simulated delete of ${publicId}`);
      return { result: 'ok', mock: true };
    }
    const result = await cloudinary.uploader.destroy(publicId, {
      resource_type: resourceType,
    });
    return result;
  } catch (err) {
    console.error(`[Cloudinary Delete Error] for ${publicId}:`, err);
    throw err;
  }
};

module.exports = {
  cloudinary,
  CLOUDINARY_FOLDERS,
  uploadBuffer,
  deleteResource,
};
