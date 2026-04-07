// models/userModel.js — Raw PostgreSQL queries for users
const pool = require('../config/db');

const UserModel = {
  // Create a new user record
  async create({ name, email, phone, password }) {
    const result = await pool.query(
      `INSERT INTO users (name, email, phone, password)
       VALUES ($1, $2, $3, $4)
       RETURNING user_id, name, email, phone, created_at`,
      [name, email, phone, password]
    );
    return result.rows[0];
  },

  // Find a user by email (used during login)
  async findByEmail(email) {
    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );
    return result.rows[0]; // returns undefined if not found
  },

  // Find a user by their primary key
  async findById(userId) {
    const result = await pool.query(
      'SELECT user_id, name, email, phone, license_image, is_verified, created_at FROM users WHERE user_id = $1',
      [userId]
    );
    return result.rows[0];
  },

  // Update license image URL after upload
  async updateLicenseImage(userId, imageUrl) {
    const result = await pool.query(
      `UPDATE users SET license_image = $1 WHERE user_id = $2
       RETURNING user_id, license_image`,
      [imageUrl, userId]
    );
    return result.rows[0];
  },

  // Mark user as KYC-verified (called after license upload)
  async setVerified(userId) {
    await pool.query(
      'UPDATE users SET is_verified = TRUE WHERE user_id = $1',
      [userId]
    );
  },
};

module.exports = UserModel;
