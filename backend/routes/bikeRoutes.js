// routes/bikeRoutes.js
const express = require('express');
const router  = express.Router();
const { getAllBikes, getBikeById } = require('../controllers/bikeController');
const { protect } = require('../middleware/authMiddleware');

// GET /api/bikes        — protected: must be logged in to browse bikes
router.get('/', protect, getAllBikes);

// GET /api/bikes/:id   — protected: get single bike details
router.get('/:id', protect, getBikeById);

module.exports = router;
