// config/db.js — PostgreSQL connection pool
const { Pool } = require('pg');
const dotenv   = require('dotenv');

dotenv.config();

// Create a connection pool (reuses connections across queries for performance)
const pool = new Pool({
  host:     process.env.DB_HOST,
  port:     process.env.DB_PORT,
  database: process.env.DB_NAME,
  user:     process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

// ── Auto-migration: add new columns safely on every startup ──────
// Uses IF NOT EXISTS so it is completely safe to re-run
const runMigrations = async (client) => {
  await client.query(`
    ALTER TABLE users
      ADD COLUMN IF NOT EXISTS license_image TEXT,
      ADD COLUMN IF NOT EXISTS is_verified   BOOLEAN DEFAULT FALSE;
  `);
  await client.query(`
    ALTER TABLE vendors
      ADD COLUMN IF NOT EXISTS email    VARCHAR(150),
      ADD COLUMN IF NOT EXISTS password VARCHAR(255);
  `);
  await client.query(`
    ALTER TABLE bikes
      ADD COLUMN IF NOT EXISTS vendor_id INTEGER REFERENCES vendors(vendor_id) ON DELETE SET NULL;
  `);
  console.log('✅ DB migrations applied (columns verified)');
};

// Test the connection on startup and run migrations
pool.connect(async (err, client, release) => {
  if (err) {
    console.error('❌ Error connecting to PostgreSQL:', err.message);
  } else {
    console.log('✅ Connected to PostgreSQL database');
    try {
      await runMigrations(client);
    } catch (migrationErr) {
      console.error('⚠️  Migration warning:', migrationErr.message);
    } finally {
      release();
    }
  }
});

module.exports = pool;

