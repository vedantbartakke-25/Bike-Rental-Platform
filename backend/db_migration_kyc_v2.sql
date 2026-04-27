CREATE TABLE IF NOT EXISTS kyc_submissions (
    kyc_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    bike_id INTEGER REFERENCES bikes(bike_id) ON DELETE CASCADE,
    vendor_id INTEGER REFERENCES vendors(vendor_id) ON DELETE CASCADE,
    license_image TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    reject_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_kyc_vendor ON kyc_submissions(vendor_id, status);
CREATE INDEX idx_kyc_user_bike ON kyc_submissions(user_id, bike_id);
