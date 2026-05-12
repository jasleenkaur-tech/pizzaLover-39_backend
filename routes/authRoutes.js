const express = require('express');
const router = express.Router();
const {
  signup,
  login,
  getMe,
  refreshToken,
  logout,
} = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

// Done
router.post('/signup', signup);
router.post('/login', login);
router.post('/refresh', refreshToken);
router.post('/logout', logout);

// Not Yet
router.get('/me', protect, getMe);

module.exports = router;
