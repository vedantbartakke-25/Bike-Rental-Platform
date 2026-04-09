// models/vendorModel.js — Raw PostgreSQL queries for vendors
const pool = require('../config/db');

const VendorModel = {
  // ── Auth ─────────────────────────────────────────────────────
  async create({ name, email, phone, password, address }) {
    const result = await pool.query(
      `INSERT INTO vendors (name, email, phone, password, address)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING vendor_id, name, email, phone, address, created_at`,
      [name, email, phone, password, address]
    );
    return result.rows[0];
  },

  async findByEmail(email) {
    const result = await pool.query(
      'SELECT * FROM vendors WHERE email = $1',
      [email]
    );
    return result.rows[0];
  },

  async findById(vendorId) {
    const result = await pool.query(
      'SELECT vendor_id, name, email, phone, address, created_at FROM vendors WHERE vendor_id = $1',
      [vendorId]
    );
    return result.rows[0];
  },

  // ── Bike Management ──────────────────────────────────────────
  async getOwnedBikes(vendorId) {
    const result = await pool.query(
      `SELECT * FROM bikes WHERE vendor_id = $1 ORDER BY bike_id`,
      [vendorId]
    );
    return result.rows;
  },

  async addBike(vendorId, { model, engine_cc, price_per_hour, price_per_day, location, bike_type, image_url }) {
    const result = await pool.query(
      `INSERT INTO bikes (vendor_id, model, engine_cc, price_per_hour, price_per_day, location, bike_type, image_url, availability)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true)
       RETURNING *`,
      [vendorId, model, engine_cc, price_per_hour, price_per_day, location, bike_type, image_url || null]
    );
    return result.rows[0];
  },

  async updateBike(bikeId, vendorId, { model, engine_cc, price_per_hour, price_per_day, location, bike_type, image_url, availability }) {
    const result = await pool.query(
      `UPDATE bikes
       SET model = COALESCE($1, model),
           engine_cc = COALESCE($2, engine_cc),
           price_per_hour = COALESCE($3, price_per_hour),
           price_per_day = COALESCE($4, price_per_day),
           location = COALESCE($5, location),
           bike_type = COALESCE($6, bike_type),
           image_url = COALESCE($7, image_url),
           availability = COALESCE($8, availability)
       WHERE bike_id = $9 AND vendor_id = $10
       RETURNING *`,
      [model, engine_cc, price_per_hour, price_per_day, location, bike_type, image_url, availability, bikeId, vendorId]
    );
    return result.rows[0]; // undefined if not owned by this vendor
  },

  async deleteBike(bikeId, vendorId) {
    const result = await pool.query(
      `DELETE FROM bikes WHERE bike_id = $1 AND vendor_id = $2 RETURNING bike_id`,
      [bikeId, vendorId]
    );
    return result.rows[0]; // undefined if not found / not owned
  },

  // ── Booking Management ───────────────────────────────────────
  async getVendorBookings(vendorId) {
    const result = await pool.query(
      `SELECT bk.booking_id, bk.start_time, bk.end_time, bk.status, bk.total_price, bk.created_at,
              u.name        AS user_name,  u.email AS user_email, u.phone AS user_phone,
              u.is_verified AS is_verified,
              b.model AS bike_model, b.bike_id, b.bike_type
       FROM bookings bk
       JOIN bikes    b ON bk.bike_id  = b.bike_id
       JOIN users    u ON bk.user_id  = u.user_id
       WHERE b.vendor_id = $1
       ORDER BY bk.created_at DESC`,
      [vendorId]
    );
    return result.rows;
  },

  async updateBookingStatus(bookingId, vendorId, status) {
    // Only allow update if the booking belongs to a bike owned by this vendor
    const result = await pool.query(
      `UPDATE bookings bk
       SET status = $1
       FROM bikes b
       WHERE bk.booking_id = $2
         AND bk.bike_id = b.bike_id
         AND b.vendor_id = $3
       RETURNING bk.*`,
      [status, bookingId, vendorId]
    );
    return result.rows[0];
  },

  // ── Dashboard Stats ──────────────────────────────────────────
  async getDashboardStats(vendorId) {
    const bikesRes = await pool.query(
      `SELECT COUNT(*) AS total_bikes FROM bikes WHERE vendor_id = $1`,
      [vendorId]
    );

    const bookingsRes = await pool.query(
      `SELECT
          COUNT(*) FILTER (WHERE bk.status IN ('confirmed','active')) AS active_bookings,
         COUNT(*) FILTER (WHERE bk.status = 'completed')                     AS completed_bookings,
         COALESCE(SUM(bk.total_price) FILTER (WHERE bk.status = 'completed'), 0) AS total_earnings
       FROM bookings bk
       JOIN bikes b ON bk.bike_id = b.bike_id
       WHERE b.vendor_id = $1`,
      [vendorId]
    );

    return {
      totalBikes:        parseInt(bikesRes.rows[0].total_bikes),
      activeBookings:    parseInt(bookingsRes.rows[0].active_bookings),
      completedBookings: parseInt(bookingsRes.rows[0].completed_bookings),
      totalEarnings:     parseFloat(bookingsRes.rows[0].total_earnings),
    };
  },
};

module.exports = VendorModel;
