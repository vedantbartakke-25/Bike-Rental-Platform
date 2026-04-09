// routes/bookingRoutes.js
const express = require('express');
const router  = express.Router();
const { createBooking, getUserBookings } = require('../controllers/bookingController');
const { protect } = require('../middleware/authMiddleware');

// POST /api/bookings             — create a new booking (auth required)
router.post('/', protect, createBooking);

// GET  /api/bookings/user/:id    — get all bookings for a user (auth required)
router.get('/user/:id', protect, getUserBookings);

module.exports = router;
