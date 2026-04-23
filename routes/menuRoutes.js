const express = require('express');
const router = express.Router();
const {
  getMenu,
  getMenuItemById,
  addMenuItem,
  updateMenuItem,
  deleteMenuItem,
} = require('../controllers/menuController');
const { protect, adminOnly } = require('../middleware/authMiddleware');

// Public routes
router.get('/', getMenu);
router.get('/:id', getMenuItemById);

// Admin-only routes
router.post('/', protect, adminOnly, addMenuItem);
router.put('/:id', protect, adminOnly, updateMenuItem);
router.delete('/:id', protect, adminOnly, deleteMenuItem);

module.exports = router;
