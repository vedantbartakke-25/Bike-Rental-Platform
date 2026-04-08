// controllers/bikeController.js — List & get bikes
const BikeModel = require('../models/bikeModel');

// ── GET /api/bikes ───────────────────────────────────────────
// Optional query params: ?start_time=ISO&end_time=ISO
// If provided → returns only bikes with no overlapping bookings
// If omitted  → returns all bikes (for bike-list / vendor management)
const getAllBikes = async (req, res) => {
  try {
    const { start_time, end_time } = req.query;

    let bikes;
    if (start_time && end_time) {
      const start = new Date(start_time);
      const end   = new Date(end_time);
      if (isNaN(start) || isNaN(end) || end <= start) {
        return res.status(400).json({ error: 'Invalid start_time or end_time.' });
      }
      // Auto-mark expired bookings as completed before filtering
      await BikeModel.autoCompleteExpired();
      bikes = await BikeModel.getAvailable(start, end);
    } else {
      bikes = await BikeModel.getAll();
    }

    res.json({ bikes });
  } catch (err) {
    console.error('getAllBikes error:', err.message);
    res.status(500).json({ error: 'Failed to fetch bikes.' });
  }
};

// ── GET /api/bikes/:id ───────────────────────────────────────
const getBikeById = async (req, res) => {
  try {
    const { id } = req.params;

    if (isNaN(id)) {
      return res.status(400).json({ error: 'Bike ID must be a number.' });
    }

    const bike = await BikeModel.getById(id);
    if (!bike) {
      return res.status(404).json({ error: 'Bike not found.' });
    }

    res.json({ bike });
  } catch (err) {
    console.error('getBikeById error:', err.message);
    res.status(500).json({ error: 'Failed to fetch bike.' });
  }
};

module.exports = { getAllBikes, getBikeById };
