-- ============================================================
-- Smart Bike Rental — PostgreSQL Schema
-- Run this file to create all required tables:
--   psql -U postgres -d bike_rental_db -f schema.sql
-- ============================================================

-- 1. Users — stores registered user accounts
CREATE TABLE IF NOT EXISTS users (
  user_id       SERIAL PRIMARY KEY,
  name          VARCHAR(100)  NOT NULL,
  email         VARCHAR(150)  UNIQUE NOT NULL,
  phone         VARCHAR(20),
  password      VARCHAR(255)  NOT NULL,          -- bcrypt hash
  license_image VARCHAR(300),                    -- Cloudinary URL
  is_verified   BOOLEAN       DEFAULT FALSE,     -- TRUE after driving license uploaded
  created_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

-- 2. Vendors — bike shop owners / rental providers
CREATE TABLE IF NOT EXISTS vendors (
  vendor_id  SERIAL PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  email      VARCHAR(150) UNIQUE NOT NULL,       -- login email
  phone      VARCHAR(20),
  password   VARCHAR(255) NOT NULL,              -- bcrypt hash
  address    TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Bikes — available bikes for rental
CREATE TABLE IF NOT EXISTS bikes (
  bike_id        SERIAL PRIMARY KEY,
  vendor_id      INTEGER    REFERENCES vendors(vendor_id) ON DELETE SET NULL,
  model          VARCHAR(100) NOT NULL,
  price_per_hour NUMERIC(10, 2) NOT NULL,
  price_per_day  NUMERIC(10, 2) NOT NULL,
  location       VARCHAR(200),
  availability   BOOLEAN    DEFAULT TRUE,         -- TRUE = available
  image_url      VARCHAR(300),                    -- Cloudinary image URL
  engine_cc      INTEGER,                         -- Engine displacement in CC
  bike_type      VARCHAR(50)                      -- e.g. scooter, cruiser, electric
);

-- 4. Bookings — rental reservations made by users
CREATE TABLE IF NOT EXISTS bookings (
  booking_id  SERIAL PRIMARY KEY,
  user_id     INTEGER   REFERENCES users(user_id)   ON DELETE CASCADE,
  bike_id     INTEGER   REFERENCES bikes(bike_id)   ON DELETE CASCADE,
  start_time  TIMESTAMP NOT NULL,
  end_time    TIMESTAMP NOT NULL,
  total_price NUMERIC(10, 2),
  status      VARCHAR(30) DEFAULT 'pending',       -- pending | active | completed | cancelled
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Payments — payment records for bookings
CREATE TABLE IF NOT EXISTS payments (
  payment_id     SERIAL PRIMARY KEY,
  booking_id     INTEGER  REFERENCES bookings(booking_id) ON DELETE CASCADE,
  amount         NUMERIC(10, 2) NOT NULL,
  payment_method VARCHAR(50),                     -- e.g. cash, upi, card
  payment_status VARCHAR(30) DEFAULT 'pending',   -- pending | completed | failed
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── Indexes for faster lookups ───────────────────────────────
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_bike_id ON bookings(bike_id);
CREATE INDEX IF NOT EXISTS idx_bikes_availability ON bikes(availability);
