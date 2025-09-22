const jwt = require('jsonwebtoken');

const auth = (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');

  if (!token) {
    return res.status(401).json({ message: 'No token, authorization denied' });
  }

  try {
    // Allow demo tokens for development
    if (token.startsWith('demo-admin-token-')) {
      req.user = { 
        id: 1, 
        username: 'superadmin', 
        role: 'administrator' 
      };
      return next();
    }

    // Regular JWT verification
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Token is not valid' });
  }
};

module.exports = auth;