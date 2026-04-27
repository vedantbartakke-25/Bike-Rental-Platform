// controllers/vendorController.js — Vendor Portal API handlers
const bcrypt      = require('bcryptjs');
const jwt         = require('jsonwebtoken');
const multer      = require('multer');
const cloudinary  = require('cloudinary').v2;
const VendorModel = require('../models/vendorModel');
const BikeModel   = require('../models/bikeModel');
const KycModel    = require('../models/kycModel');

// ── Cloudinary (same config as uploadRoutes.js) ──────────────
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// ── Multer — memory storage for Cloudinary upload ────────────
const storage = multer.memoryStorage();
const upload  = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) cb(null, true);
    else cb(new Error('Only image files are allowed.'), false);
  },
});

// Export the multer middleware so routes can use it
const uploadBikeImage = upload.single('image');

// ── Helper: generate vendor JWT ──────────────────────────────
const generateVendorToken = (vendorId, email) =>
  jwt.sign(
    { vendor_id: vendorId, email, role: 'vendor' },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );

// ── Helper: upload buffer to Cloudinary ─────────────────────
const uploadToCloudinary = (buffer, vendorId) =>
  new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: 'bike_rental/bikes',
        public_id: `vendor_${vendorId}_bike_${Date.now()}`,
        overwrite: true,
        resource_type: 'image',
      },
      (error, result) => (error ? reject(error) : resolve(result))
    );
    stream.end(buffer);
  });

// ════════════════════════════════════════════════════════════════
// AUTH
// ════════════════════════════════════════════════════════════════

// POST /api/vendor/register
const registerVendor = async (req, res) => {
  try {
    const { name, email, phone, password, address } = req.body;

    if (!name || !email || !password)
      return res.status(400).json({ error: 'Name, email, and password are required.' });

    if (password.length < 6)
      return res.status(400).json({ error: 'Password must be at least 6 characters.' });

    const existing = await VendorModel.findByEmail(email);
    if (existing)
      return res.status(409).json({ error: 'Email already registered as a vendor.' });

    const hashed = await bcrypt.hash(password, 10);
    const vendor  = await VendorModel.create({ name, email, phone, password: hashed, address });

    const token = generateVendorToken(vendor.vendor_id, vendor.email);
    res.status(201).json({
      message: 'Vendor registered successfully.',
      token,
      vendor: { id: vendor.vendor_id, name: vendor.name, email: vendor.email },
    });
  } catch (err) {
    console.error('registerVendor error:', err.message);
    res.status(500).json({ error: 'Server error during vendor registration.' });
  }
};

// POST /api/vendor/login
const loginVendor = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password)
      return res.status(400).json({ error: 'Email and password are required.' });

    const vendor = await VendorModel.findByEmail(email);
    if (!vendor)
      return res.status(401).json({ error: 'Invalid email or password.' });

    const isMatch = await bcrypt.compare(password, vendor.password);
    if (!isMatch)
      return res.status(401).json({ error: 'Invalid email or password.' });

    const token = generateVendorToken(vendor.vendor_id, vendor.email);
    res.json({
      message: 'Vendor login successful.',
      token,
      vendor: { id: vendor.vendor_id, name: vendor.name, email: vendor.email },
    });
  } catch (err) {
    console.error('loginVendor error:', err.message);
    res.status(500).json({ error: 'Server error during vendor login.' });
  }
};

// GET /api/vendor/profile
const getVendorProfile = async (req, res) => {
  try {
    const vendor = await VendorModel.findById(req.vendor.vendor_id);
    if (!vendor) return res.status(404).json({ error: 'Vendor not found.' });
    res.json({ vendor });
  } catch (err) {
    console.error('getVendorProfile error:', err.message);
    res.status(500).json({ error: 'Failed to fetch vendor profile.' });
  }
};

// ════════════════════════════════════════════════════════════════
// BIKE MANAGEMENT
// ════════════════════════════════════════════════════════════════

// GET /api/vendor/bikes
const getVendorBikes = async (req, res) => {
  try {
    const bikes = await VendorModel.getOwnedBikes(req.vendor.vendor_id);
    res.json({ bikes });
  } catch (err) {
    console.error('getVendorBikes error:', err.message);
    res.status(500).json({ error: 'Failed to fetch vendor bikes.' });
  }
};

// POST /api/vendor/bikes  (multipart/form-data with optional image field)
const addBike = async (req, res) => {
  try {
    const { model, engine_cc, price_per_hour, price_per_day, location, bike_type } = req.body;

    if (!model || !price_per_day)
      return res.status(400).json({ error: 'model and price_per_day are required.' });

    let image_url = null;
    if (req.file) {
      const result = await uploadToCloudinary(req.file.buffer, req.vendor.vendor_id);
      image_url = result.secure_url;
    }

    const bike = await VendorModel.addBike(req.vendor.vendor_id, {
      model, engine_cc, price_per_hour, price_per_day, location, bike_type, image_url,
    });

    res.status(201).json({ message: 'Bike added successfully.', bike });
  } catch (err) {
    console.error('addBike error:', err.message);
    res.status(500).json({ error: 'Failed to add bike.' });
  }
};

// PUT /api/vendor/bikes/:id
const updateBike = async (req, res) => {
  try {
    const { id } = req.params;

    let image_url = undefined; // undefined → COALESCE keeps existing value
    if (req.file) {
      const result = await uploadToCloudinary(req.file.buffer, req.vendor.vendor_id);
      image_url = result.secure_url;
    }

    const bike = await VendorModel.updateBike(id, req.vendor.vendor_id, { ...req.body, image_url });

    if (!bike)
      return res.status(404).json({ error: 'Bike not found or not owned by you.' });

    res.json({ message: 'Bike updated successfully.', bike });
  } catch (err) {
    console.error('updateBike error:', err.message);
    res.status(500).json({ error: 'Failed to update bike.' });
  }
};

// DELETE /api/vendor/bikes/:id
const deleteBike = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await VendorModel.deleteBike(id, req.vendor.vendor_id);

    if (!deleted)
      return res.status(404).json({ error: 'Bike not found or not owned by you.' });

    res.json({ message: 'Bike deleted successfully.' });
  } catch (err) {
    console.error('deleteBike error:', err.message);
    res.status(500).json({ error: 'Failed to delete bike.' });
  }
};

// ════════════════════════════════════════════════════════════════
// BOOKING MANAGEMENT
// ════════════════════════════════════════════════════════════════

// GET /api/vendor/bookings
const getVendorBookings = async (req, res) => {
  try {
    // Auto-complete expired bookings before fetching
    await BikeModel.autoCompleteExpired();
    const bookings = await VendorModel.getVendorBookings(req.vendor.vendor_id);
    res.json({ bookings });
  } catch (err) {
    console.error('getVendorBookings error:', err.message);
    res.status(500).json({ error: 'Failed to fetch bookings.' });
  }
};

// PATCH /api/vendor/bookings/:id/status
const updateBookingStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const validStatuses = ['confirmed', 'active', 'completed', 'cancelled'];
    if (!status || !validStatuses.includes(status))
      return res.status(400).json({ error: `Status must be one of: ${validStatuses.join(', ')}` });

    const booking = await VendorModel.updateBookingStatus(id, req.vendor.vendor_id, status);

    if (!booking)
      return res.status(404).json({ error: 'Booking not found or not related to your bikes.' });

    res.json({ message: 'Booking status updated.', booking });
  } catch (err) {
    console.error('updateBookingStatus error:', err.message);
    res.status(500).json({ error: 'Failed to update booking status.' });
  }
};

// ════════════════════════════════════════════════════════════════
// DASHBOARD
// ════════════════════════════════════════════════════════════════

// GET /api/vendor/dashboard
const getDashboard = async (req, res) => {
  try {
    // Auto-complete expired bookings before computing stats
    await BikeModel.autoCompleteExpired();
    const stats = await VendorModel.getDashboardStats(req.vendor.vendor_id);
    res.json({ stats });
  } catch (err) {
    console.error('getDashboard error:', err.message);
    res.status(500).json({ error: 'Failed to fetch dashboard stats.' });
  }
};

// ════════════════════════════════════════════════════════════════
// KYC MANAGEMENT
// ════════════════════════════════════════════════════════════════

const getPendingKyc = async (req, res) => {
  try {
    const kycList = await KycModel.getPendingByVendor(req.vendor.vendor_id);
    res.json({ kycList });
  } catch (err) {
    console.error('getPendingKyc error:', err.message);
    res.status(500).json({ error: 'Failed to fetch pending KYC submissions.' });
  }
};

const getAllKyc = async (req, res) => {
  try {
    const kycList = await KycModel.getAllByVendor(req.vendor.vendor_id);
    res.json({ kycList });
  } catch (err) {
    console.error('getAllKyc error:', err.message);
    res.status(500).json({ error: 'Failed to fetch all KYC submissions.' });
  }
};

const approveKyc = async (req, res) => {
  try {
    const { id } = req.params;
    const kyc = await KycModel.approve(id);
    res.json({ message: 'KYC approved.', kyc });
  } catch (err) {
    console.error('approveKyc error:', err.message);
    res.status(500).json({ error: 'Failed to approve KYC.' });
  }
};

const rejectKyc = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const kyc = await KycModel.reject(id, reason);
    res.json({ message: 'KYC rejected.', kyc });
  } catch (err) {
    console.error('rejectKyc error:', err.message);
    res.status(500).json({ error: 'Failed to reject KYC.' });
  }
};

const getKycPendingCount = async (req, res) => {
  try {
    const count = await KycModel.getPendingCount(req.vendor.vendor_id);
    res.json({ count });
  } catch (err) {
    console.error('getKycPendingCount error:', err.message);
    res.status(500).json({ error: 'Failed to fetch KYC pending count.' });
  }
};


module.exports = {
  registerVendor,
  loginVendor,
  getVendorProfile,
  getVendorBikes,
  addBike,
  updateBike,
  deleteBike,
  getVendorBookings,
  updateBookingStatus,
  getDashboard,
  uploadBikeImage,
  getPendingKyc,
  getAllKyc,
  approveKyc,
  rejectKyc,
  getKycPendingCount,
};
