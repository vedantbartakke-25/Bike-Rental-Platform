// controllers/bookingController.js — Create & list bookings
const BookingModel = require('../models/bookingModel');
const pool         = require('../config/db');
const BikeModel    = require('../models/bikeModel');
const UserModel    = require('../models/userModel');
const KycModel     = require('../models/kycModel');

// ── POST /api/bookings ───────────────────────────────────────
const createBooking = async (req, res) => {
  try {
    const { bike_id, start_time, end_time, payment_method } = req.body;
    const userId = req.user.userId; // injected by authMiddleware

    // 1. Validate required fields
    if (!bike_id || !start_time || !end_time) {
      return res.status(400).json({ error: 'bike_id, start_time, and end_time are required.' });
    }

    // 2. KYC check — user must have an approved KYC for this specific bike
    const isApproved = await KycModel.isApprovedForBike(userId, bike_id);
    if (!isApproved) {
      return res.status(403).json({
        error: 'Vendor approval of your driving license is required for this bike.',
        kyc_required: true,
      });
    }

    // 2. Parse timestamps
    const start = new Date(start_time);
    const end   = new Date(end_time);
    if (isNaN(start) || isNaN(end) || end <= start) {
      return res.status(400).json({ error: 'Invalid time range. end_time must be after start_time.' });
    }

    // Reject bookings in the past (with 2-minute grace window)
    const now = new Date();
    if (start < new Date(now.getTime() - 2 * 60 * 1000)) {
      return res.status(400).json({ error: 'Start time cannot be in the past.' });
    }

    // 3. Check bike exists and has no overlapping active/approved bookings
    const bike = await BikeModel.getById(bike_id);
    if (!bike) return res.status(404).json({ error: 'Bike not found.' });

    // DB-level time-overlap guard (same logic as getAvailable)
    const available = await BikeModel.getAvailable(start, end);
    const bikeIsAvailable = available.some(b => b.bike_id === parseInt(bike_id));
    if (!bikeIsAvailable) {
      return res.status(409).json({ error: 'Bike is already booked for the selected time period.' });
    }

    // 4. Calculate total price (based on hours, then scale to days if needed)
    const hours      = (end - start) / (1000 * 60 * 60); // milliseconds → hours
    const days       = hours / 24;
    // Use per_day rate if booking ≥ 12 hours (better value for user)
    const totalPrice = days >= 0.5
      ? (Math.ceil(days) * parseFloat(bike.price_per_day))
      : (hours * parseFloat(bike.price_per_hour));

    // 5. Save booking
    const booking = await BookingModel.create({
      userId,
      bikeId: bike_id,
      startTime: start,
      endTime: end,
      totalPrice: totalPrice.toFixed(2),
    });

    // 6. Record payment in the payments table
    const method = payment_method || 'cod';
    await pool.query(
      `INSERT INTO payments (booking_id, amount, payment_method, payment_status)
       VALUES ($1, $2, $3, $4)`,
      [booking.booking_id, totalPrice.toFixed(2), method, method === 'cod' ? 'pending' : 'completed']
    );

    res.status(201).json({ message: 'Booking created successfully.', booking });
  } catch (err) {
    console.error('createBooking error:', err.message);
    res.status(500).json({ error: 'Failed to create booking.' });
  }
};

// ── GET /api/bookings/user/:id ───────────────────────────────
const getUserBookings = async (req, res) => {
  try {
    const { id } = req.params;

    // Ensure the logged-in user can only view their own bookings
    if (parseInt(id) !== req.user.userId) {
      return res.status(403).json({ error: 'Access forbidden.' });
    }

    const bookings = await BookingModel.getByUserId(id);
    res.json({ bookings });
  } catch (err) {
    console.error('getUserBookings error:', err.message);
    res.status(500).json({ error: 'Failed to fetch bookings.' });
  }
};

module.exports = { createBooking, getUserBookings };
