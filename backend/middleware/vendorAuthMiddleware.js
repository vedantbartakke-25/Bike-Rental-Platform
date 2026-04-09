// middleware/vendorAuthMiddleware.js — JWT verification for vendor routes
const jwt = require('jsonwebtoken');

/**
 * Protect vendor routes by verifying a Bearer JWT token
 * and confirming role === 'vendor'.
 * Attaches decoded vendor info to req.vendor on success.
 */
const vendorProtect = (req, res, next) => {
  const authHeader = req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided. Access denied.' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Only allow vendor tokens
    if (decoded.role !== 'vendor') {
      return res.status(403).json({ error: 'Access restricted to vendors only.' });
    }

    req.vendor = decoded; // { vendor_id, email, role: 'vendor' }
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
};

module.exports = { vendorProtect };
