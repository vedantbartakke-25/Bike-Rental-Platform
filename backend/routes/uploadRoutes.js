// routes/uploadRoutes.js — License image upload via Multer + Cloudinary
const express    = require('express');
const router     = express.Router();
const multer     = require('multer');
const cloudinary = require('cloudinary').v2;
const dotenv     = require('dotenv');
const { protect } = require('../middleware/authMiddleware');
const UserModel   = require('../models/userModel');
const BikeModel   = require('../models/bikeModel');
const KycModel    = require('../models/kycModel');

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

    const { bike_id } = req.body;
    if (!bike_id) {
      return res.status(400).json({ error: 'bike_id is required.' });
    }

    const bike = await BikeModel.getById(bike_id);
    if (!bike) {
      return res.status(404).json({ error: 'Bike not found.' });
    }

    // Upload the buffer to Cloudinary using a stream
    const result = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          folder: 'bike_rental/licenses',        // Cloudinary folder
          public_id: `user_${req.user.userId}_bike_${bike_id}_license_${Date.now()}`,
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

    // Save Cloudinary URL to user record (optional, if still keeping it globally)
    const updated = await UserModel.updateLicenseImage(req.user.userId, result.secure_url);

    // Create a pending KYC submission for this specific bike and vendor
    const kycSubmission = await KycModel.create({
      userId: req.user.userId,
      bikeId: bike_id,
      vendorId: bike.vendor_id,
      licenseImage: result.secure_url,
    });

    res.json({
      message: 'License uploaded successfully. Waiting for vendor approval.',
      license_image: result.secure_url,
      kyc: kycSubmission,
      user: updated,
    });
  } catch (err) {
    console.error('Upload error:', err.message);
    res.status(500).json({ error: 'Failed to upload license image.' });
  }
});

// ── GET /api/kyc-status ───────────────────────────────────────
router.get('/kyc-status', protect, async (req, res) => {
  try {
    const { bike_id } = req.query;
    if (!bike_id) {
      return res.status(400).json({ error: 'bike_id is required.' });
    }

    const kyc = await KycModel.findByUserAndBike(req.user.userId, bike_id);
    if (!kyc) {
      return res.json({ status: 'none' });
    }

    res.json({
      status: kyc.status, // 'pending', 'approved', 'rejected'
      reject_reason: kyc.reject_reason,
    });
  } catch (err) {
    console.error('KYC status error:', err.message);
    res.status(500).json({ error: 'Failed to get KYC status.' });
  }
});

module.exports = router;
