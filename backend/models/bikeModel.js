// models/bikeModel.js — Raw PostgreSQL queries for bikes
const pool = require('../config/db');

const BikeModel = {
  // Get ALL bikes (used by vendor management, bike detail page, etc.)
  async getAll() {
    const result = await pool.query(
      `SELECT b.*, v.name AS vendor_name, v.address AS vendor_address
       FROM bikes b
       LEFT JOIN vendors v ON b.vendor_id = v.vendor_id
       ORDER BY b.bike_id`
    );
    return result.rows;
  },

  // Get bikes available for a specific time window (time-based, not boolean flag)
  // A bike is available if no 'approved' or 'active' booking overlaps the requested window
  async getAvailable(startTime, endTime) {
    const result = await pool.query(
      `SELECT b.*, v.name AS vendor_name, v.address AS vendor_address
       FROM bikes b
       LEFT JOIN vendors v ON b.vendor_id = v.vendor_id
       WHERE NOT EXISTS (
         SELECT 1 FROM bookings bk
         WHERE bk.bike_id = b.bike_id
           AND bk.status IN ('confirmed', 'active')
           AND NOT (
             bk.end_time   <= $1 OR
             bk.start_time >= $2
           )
       )
       ORDER BY b.bike_id`,
      [startTime, endTime]
    );
    return result.rows;
  },

  // Get a single bike by ID
  async getById(bikeId) {
    const result = await pool.query(
      `SELECT b.*, v.name AS vendor_name, v.phone AS vendor_phone, v.address AS vendor_address
       FROM bikes b
       LEFT JOIN vendors v ON b.vendor_id = v.vendor_id
       WHERE b.bike_id = $1`,
      [bikeId]
    );
    return result.rows[0];
  },

  // Auto-complete expired bookings and reset bike availability flag
  async autoCompleteExpired() {
    // 1. Mark past approved/active bookings as completed
    const result = await pool.query(
      `UPDATE bookings
       SET status = 'completed'
       WHERE status IN ('confirmed', 'active')
         AND end_time < NOW()
       RETURNING bike_id`
    );
    // 2. Reset availability = true for those bikes (repairs stale boolean)
    if (result.rows.length > 0) {
      const bikeIds = result.rows.map(r => r.bike_id);
      await pool.query(
        `UPDATE bikes SET availability = TRUE WHERE bike_id = ANY($1::int[])`,
        [bikeIds]
      );
    }
  },

  // Keep for backward compatibility (vendor bike management still sets this)
  async setAvailability(bikeId, isAvailable) {
    await pool.query(
      'UPDATE bikes SET availability = $1 WHERE bike_id = $2',
      [isAvailable, bikeId]
    );
  },
};

module.exports = BikeModel;

