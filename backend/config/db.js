// config/db.js — PostgreSQL connection pool (Supabase pooler)

const { Pool } = require('pg');
const dotenv = require('dotenv');

dotenv.config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false,
  },
  // ── Pool settings tuned for Supabase free-tier ──────────────
  max: 5,                      // limit concurrent connections
  idleTimeoutMillis: 30000,    // close idle connections after 30s
  connectionTimeoutMillis: 30000, // wait up to 30s for a connection
});

// Log pool-level errors so they don't crash the server
pool.on('error', (err) => {
  console.error('⚠️  Idle pool client error:', err.message);
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

// ── Connect with retry logic ────────────────────────────────
const connectWithRetry = async (retries = 5, delay = 3000) => {
  for (let attempt = 1; attempt <= retries; attempt++) {
    let client;
    try {
      client = await pool.connect();
      console.log('✅ Connected to PostgreSQL database');
      await runMigrations(client);
      return; // success — stop retrying
    } catch (err) {
      console.error(`❌ DB connection attempt ${attempt}/${retries} failed:`, err.message);
      if (attempt < retries) {
        console.log(`   Retrying in ${delay / 1000}s...`);
        await new Promise((r) => setTimeout(r, delay));
      } else {
        console.error('❌ All DB connection attempts failed. The server will still start, but queries may fail.');
      }
    } finally {
      if (client) client.release();
    }
  }
};

connectWithRetry();

module.exports = pool;