// config/db.js — PostgreSQL connection pool (Supabase pooler)

const { Pool } = require('pg');
const dotenv = require('dotenv');

dotenv.config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false,
  },
});

// ── Auto-migration ──────
const runMigrations = async (client) => {
  await client.query(`
    ALTER TABLE users
      ADD COLUMN IF NOT EXISTS license_image TEXT,
      ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;
  `);

  await client.query(`
    ALTER TABLE vendors
      ADD COLUMN IF NOT EXISTS email VARCHAR(150),
      ADD COLUMN IF NOT EXISTS password VARCHAR(255);
  `);

  await client.query(`
    ALTER TABLE bikes
      ADD COLUMN IF NOT EXISTS vendor_id INTEGER 
      REFERENCES vendors(vendor_id) ON DELETE SET NULL;
  `);

  console.log('✅ DB migrations applied');
};

// Test connection
(async () => {
  let client;
  try {
    client = await pool.connect();
    console.log('✅ Connected to PostgreSQL database');

    await runMigrations(client);

  } catch (err) {
    console.error('❌ DB connection error:', err.message);

  } finally {
    if (client) client.release();
  }
})();

module.exports = pool;