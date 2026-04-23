const express = require('express');
const router = express.Router();
const { placeOrder, getMyOrders, getOrderById } = require('../controllers/orderController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect); // All order routes require authentication

router.post('/createOrder', placeOrder);
router.get('/my-orders', getMyOrders);
router.get('/:id', getOrderById);

module.exports = router;
