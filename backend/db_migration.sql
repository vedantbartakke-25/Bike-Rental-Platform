-- ============================================================
-- Smart Bike Rental — Migration: KYC + Vendor Auth Columns
-- Run ONCE against an existing database:
--   psql -U postgres -d bike_rental_db -f db_migration.sql
-- ============================================================

-- 1. Add KYC columns to users table (safe: IF NOT EXISTS)
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS license_image TEXT,
  ADD COLUMN IF NOT EXISTS is_verified   BOOLEAN DEFAULT FALSE;

-- 2. Add auth columns to vendors table (safe: IF NOT EXISTS)
ALTER TABLE vendors
  ADD COLUMN IF NOT EXISTS email    VARCHAR(150) UNIQUE,
  ADD COLUMN IF NOT EXISTS password VARCHAR(255);

-- 3. Add vendor_id FK to bikes table (safe: IF NOT EXISTS)
ALTER TABLE bikes
  ADD COLUMN IF NOT EXISTS vendor_id INTEGER REFERENCES vendors(vendor_id) ON DELETE SET NULL;

-- 4. Extend booking status to support vendor workflow values
--    (existing 'pending'/'active'/'completed'/'cancelled' still valid)
--    No schema change needed — status column is already VARCHAR(30).

-- ── Verification queries ─────────────────────────────────────
-- Run after migration to confirm columns exist:
-- SELECT column_name, data_type FROM information_schema.columns
-- WHERE table_name = 'users' AND column_name IN ('license_image','is_verified');
