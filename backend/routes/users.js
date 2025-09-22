const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');

router.get('/profile', auth, (req, res) => {
  res.json({
    user: {
      id: req.user.userId,
      username: req.user.username
    }
  });
});

module.exports = router;