// routes/uploadRoutes.js — License image upload via Multer + Cloudinary
const express    = require('express');
const router     = express.Router();
const multer     = require('multer');
const cloudinary = require('cloudinary').v2;
const dotenv     = require('dotenv');
const { protect } = require('../middleware/authMiddleware');
const UserModel   = require('../models/userModel');

dotenv.config();

// ── Cloudinary configuration ─────────────────────────────────
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// ── Multer — store files in memory before uploading to Cloudinary
const storage = multer.memoryStorage();
const upload  = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB max
  fileFilter: (req, file, cb) => {
    // Only allow image files
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed.'), false);
    }
  },
});

// ── POST /api/upload-license ─────────────────────────────────
router.post('/upload-license', protect, (req, res, next) => {
  // Run multer and intercept its errors so they return JSON (not 500)
  upload.single('license')(req, res, (err) => {
    if (err) {
      return res.status(400).json({ error: err.message });
    }
    next();
  });
}, async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded.' });
    }

    // Upload the buffer to Cloudinary using a stream
    const result = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          folder: 'bike_rental/licenses',        // Cloudinary folder
          public_id: `user_${req.user.userId}_license`,
          overwrite: true,
          resource_type: 'image',
        },
        (error, result) => {
          if (error) reject(error);
          else resolve(result);
        }
      );
      stream.end(req.file.buffer); // Send the in-memory buffer
    });

    // Save Cloudinary URL to user record
    const updated = await UserModel.updateLicenseImage(req.user.userId, result.secure_url);

    // Mark user as KYC-verified
    await UserModel.setVerified(req.user.userId);

    res.json({
      message: 'License uploaded successfully.',
      license_image: result.secure_url,
      user: updated,
    });
  } catch (err) {
    console.error('Upload error:', err.message);
    res.status(500).json({ error: 'Failed to upload license image.' });
  }
});

module.exports = router;
