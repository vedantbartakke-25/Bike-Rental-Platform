// models/bookingModel.js — Raw PostgreSQL queries for bookings
const pool = require('../config/db');

const BookingModel = {
  // Create a new booking
  async create({ userId, bikeId, startTime, endTime, totalPrice }) {
    const result = await pool.query(
      `INSERT INTO bookings (user_id, bike_id, start_time, end_time, total_price, status)
       VALUES ($1, $2, $3, $4, $5, 'confirmed')
       RETURNING *`,
      [userId, bikeId, startTime, endTime, totalPrice]
    );
    return result.rows[0];
  },

  // Get all bookings for a specific user (includes bike model name)
  async getByUserId(userId) {
    const result = await pool.query(
      `SELECT bk.*, b.model AS bike_model, b.image_url, b.bike_type
       FROM bookings bk
       JOIN bikes b ON bk.bike_id = b.bike_id
       WHERE bk.user_id = $1
       ORDER BY bk.created_at DESC`,
      [userId]
    );
    return result.rows;
  },

  // Update booking status (e.g., active → completed)
  async updateStatus(bookingId, status) {
    const result = await pool.query(
      `UPDATE bookings SET status = $1 WHERE booking_id = $2
       RETURNING *`,
      [status, bookingId]
    );
    return result.rows[0];
  },
};

module.exports = BookingModel;
