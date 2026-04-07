// middleware/authMiddleware.js — JWT verification
const jwt = require('jsonwebtoken');

/**
 * Protect routes by verifying a Bearer JWT token.
 * Attaches decoded user info to req.user on success.
 */
const protect = (req, res, next) => {
  // Expect header: Authorization: Bearer <token>
  const authHeader = req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided. Access denied.' });
  }

  const token = authHeader.split(' ')[1]; // Extract token after "Bearer "

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // e.g. { userId: 1, email: "..." }
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
};

module.exports = { protect };
