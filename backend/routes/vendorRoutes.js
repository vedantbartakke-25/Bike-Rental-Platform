// routes/vendorRoutes.js — All vendor portal API routes
const express    = require('express');
const router     = express.Router();
const { vendorProtect } = require('../middleware/vendorAuthMiddleware');
const {
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
} = require('../controllers/vendorController');

// ── Public Routes (no auth required) ────────────────────────
router.post('/register', registerVendor);
router.post('/login',    loginVendor);

// ── Protected Routes (vendor JWT required) ───────────────────
router.get('/profile',   vendorProtect, getVendorProfile);

// Bikes
router.get('/bikes',        vendorProtect, getVendorBikes);
router.post('/bikes',       vendorProtect, uploadBikeImage, addBike);
router.put('/bikes/:id',    vendorProtect, uploadBikeImage, updateBike);
router.delete('/bikes/:id', vendorProtect, deleteBike);

// Bookings
router.get('/bookings',              vendorProtect, getVendorBookings);
router.patch('/bookings/:id/status', vendorProtect, updateBookingStatus);

// Dashboard
router.get('/dashboard', vendorProtect, getDashboard);

module.exports = router;
