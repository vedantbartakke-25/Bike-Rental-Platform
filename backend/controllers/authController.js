// controllers/authController.js — Register & Login
const bcrypt   = require('bcryptjs');
const jwt      = require('jsonwebtoken');
const UserModel = require('../models/userModel');

// Helper: generate a signed JWT for a user
const generateToken = (userId, email) => {
  return jwt.sign(
    { userId, email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

// ── POST /api/auth/register ──────────────────────────────────
const register = async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;

    // 1. Basic input validation
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email, and password are required.' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters.' });
    }

    // 2. Check if email is already registered
    const existing = await UserModel.findByEmail(email);
    if (existing) {
      return res.status(409).json({ error: 'Email already in use.' });
    }

    // 3. Hash the password (salt rounds = 10)
    const hashedPassword = await bcrypt.hash(password, 10);

    // 4. Create user in DB
    const user = await UserModel.create({ name, email, phone, password: hashedPassword });

    // 5. Return JWT + basic user info
    const token = generateToken(user.user_id, user.email);
    res.status(201).json({
      message: 'Registration successful.',
      token,
      user: { id: user.user_id, name: user.name, email: user.email },
    });
  } catch (err) {
    console.error('Register error:', err.message);
    res.status(500).json({ error: 'Server error during registration.' });
  }
};

// ── POST /api/auth/login ─────────────────────────────────────
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // 1. Validate inputs
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    // 2. Find user by email
    const user = await UserModel.findByEmail(email);
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    // 3. Compare provided password with stored hash
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    // 4. Return JWT
    const token = generateToken(user.user_id, user.email);
    res.json({
      message: 'Login successful.',
      token,
      user: { id: user.user_id, name: user.name, email: user.email },
    });
  } catch (err) {
    console.error('Login error:', err.message);
    res.status(500).json({ error: 'Server error during login.' });
  }
};

// ── GET /api/user/profile ────────────────────────────────────
const getProfile = async (req, res) => {
  try {
    const user = await UserModel.findById(req.user.userId);
    if (!user) return res.status(404).json({ error: 'User not found.' });
    res.json({
      user_id:       user.user_id,
      name:          user.name,
      license_image: user.license_image || null,
      is_verified:   user.is_verified || false,
    });
  } catch (err) {
    console.error('getProfile error:', err.message);
    res.status(500).json({ error: 'Failed to fetch profile.' });
  }
};

module.exports = { register, login, getProfile };
