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

router.post('/signup', signup);
router.post('/login', login);
router.post('/refresh', refreshToken);
router.post('/logout', protect, logout);
router.get('/me', protect, getMe);

module.exports = router;
