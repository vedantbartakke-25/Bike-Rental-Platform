// server.js — Express app entry point
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

// Load environment variables from .env file
dotenv.config();

const app = express();

// ── Middleware ─────────────────────────────────────────────
app.use(cors());                         // Allow cross-origin requests (Flutter <-> backend)
app.use(express.json());                 // Parse incoming JSON request bodies
app.use(express.urlencoded({ extended: true }));

// ── Routes ─────────────────────────────────────────────────
const authRoutes    = require('./routes/authRoutes');
const bikeRoutes    = require('./routes/bikeRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const uploadRoutes  = require('./routes/uploadRoutes');
const vendorRoutes  = require('./routes/vendorRoutes');

app.use('/api/auth',     authRoutes);
app.use('/api/bikes',    bikeRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api',          uploadRoutes);
app.use('/api/vendor',   vendorRoutes);

// ── Health Check ────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({ message: 'Smart Bike Rental API is running 🚀' });
});

// ── 404 Handler ─────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// ── Global Error Handler ────────────────────────────────────
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err.message);
  res.status(500).json({ error: 'Internal server error' });
});

// ── Start Server ────────────────────────────────────────────
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`✅ Server running on http://localhost:${PORT}`);
});
