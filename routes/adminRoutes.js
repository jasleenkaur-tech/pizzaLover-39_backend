const express = require('express');
const router = express.Router();
const {
  getAllOrders,
  updateOrderStatus,
  getDashboardStats,
} = require('../controllers/adminController');
const { protect, adminOnly } = require('../middleware/authMiddleware');

router.use(protect, adminOnly); // All admin routes are protected

router.get('/orders', getAllOrders);
router.patch('/orders/:_id/status', updateOrderStatus);
router.get('/status', getDashboardStats);

module.exports = router;
