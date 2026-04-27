const pool = require('../config/db');

class KycModel {
  static async create({ userId, bikeId, vendorId, licenseImage }) {
    const result = await pool.query(
      `INSERT INTO kyc_submissions (user_id, bike_id, vendor_id, license_image, status)
       VALUES ($1, $2, $3, $4, 'pending')
       RETURNING *`,
      [userId, bikeId, vendorId, licenseImage]
    );
    return result.rows[0];
  }

  static async findByUserAndBike(userId, bikeId) {
    const result = await pool.query(
      `SELECT * FROM kyc_submissions 
       WHERE user_id = $1 AND bike_id = $2 
       ORDER BY created_at DESC LIMIT 1`,
      [userId, bikeId]
    );
    return result.rows[0];
  }

  static async getPendingByVendor(vendorId) {
    const result = await pool.query(
      `SELECT k.*, u.name as user_name, u.email as user_email, b.model as bike_model 
       FROM kyc_submissions k
       JOIN users u ON k.user_id = u.user_id
       JOIN bikes b ON k.bike_id = b.bike_id
       WHERE k.vendor_id = $1 AND k.status = 'pending'
       ORDER BY k.created_at ASC`,
      [vendorId]
    );
    return result.rows;
  }

  static async getAllByVendor(vendorId) {
    const result = await pool.query(
      `SELECT k.*, u.name as user_name, u.email as user_email, b.model as bike_model 
       FROM kyc_submissions k
       JOIN users u ON k.user_id = u.user_id
       JOIN bikes b ON k.bike_id = b.bike_id
       WHERE k.vendor_id = $1
       ORDER BY k.created_at DESC`,
      [vendorId]
    );
    return result.rows;
  }

  static async approve(kycId) {
    const result = await pool.query(
      `UPDATE kyc_submissions SET status = 'approved', updated_at = CURRENT_TIMESTAMP
       WHERE kyc_id = $1 RETURNING *`,
      [kycId]
    );
    return result.rows[0];
  }

  static async reject(kycId, reason) {
    const result = await pool.query(
      `UPDATE kyc_submissions SET status = 'rejected', reject_reason = $2, updated_at = CURRENT_TIMESTAMP
       WHERE kyc_id = $1 RETURNING *`,
      [kycId, reason]
    );
    return result.rows[0];
  }

  static async isApprovedForBike(userId, bikeId) {
    const result = await pool.query(
      `SELECT 1 FROM kyc_submissions 
       WHERE user_id = $1 AND bike_id = $2 AND status = 'approved' 
       LIMIT 1`,
      [userId, bikeId]
    );
    return result.rows.length > 0;
  }

  static async getPendingCount(vendorId) {
    const result = await pool.query(
      `SELECT COUNT(*) FROM kyc_submissions WHERE vendor_id = $1 AND status = 'pending'`,
      [vendorId]
    );
    return parseInt(result.rows[0].count, 10);
  }
}

module.exports = KycModel;
