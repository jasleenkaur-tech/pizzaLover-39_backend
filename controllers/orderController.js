const Order = require('../models/Order');
const MenuItem = require('../models/MenuItem');
const { getPaginationOptions, buildPaginationMeta } = require('../utils/pagination');
const { notifyOrderUser } = require('../utils/notificationService');

const VALID_PAYMENT_METHODS = ['cashOnDelivery', 'razorpay', 'upi', 'card', 'wallet'];

// @desc    Place a new order
// @route   POST /api/orders
// @access  Private
exports.placeOrder = async (req, res) => {
  console.log('Placing order with data:', req.body);
  try {
    const { items, paymentMethod, customerDetails } = req.body;
    const user=req.user;
    if (!items || items.length === 0) {
      return res.status(400).json({ success: false, message: 'Order must have at least one item.' });
    }
    if (!customerDetails?.name || !customerDetails?.phone || !customerDetails?.address) {
      return res.status(400).json({ success: false, message: 'Customer name, phone, and address are required.' });
    }
    if (!VALID_PAYMENT_METHODS.includes(paymentMethod)) {
      return res.status(400).json({
        success: false,
        message: `paymentMethod must be one of: ${VALID_PAYMENT_METHODS.join(', ')}.`,
      });
    }

    // Validate items and build order items with price snapshots
    const orderItems = [];
    let subtotal = 0;

    for (const item of items) {
      const menuItem = await MenuItem.findById(item.menuItemId);
      if (!menuItem) {
        return res.status(404).json({ success: false, message: `Menu item ${item.menuItemId} not found.` });
      }
      if (!menuItem.isAvailable) {
        return res.status(400).json({ success: false, message: `"${menuItem.name}" is currently unavailable.` });
      }

      const price = menuItem.prices.get(item.size);
      if (price === undefined) {
        return res.status(400).json({
          success: false,
          message: `Size "${item.size}" not available for "${menuItem.name}".`,
        });
      }

      const itemTotal = price * item.quantity;
      subtotal += itemTotal;

      orderItems.push({
        menuItem: menuItem._id,
        name: menuItem.name,
        size: item.size,
        price,
        quantity: item.quantity,
        emoji: menuItem.emoji,
      });
    }
    const deliveryFee=(subtotal > 500 ? 0 : 30)
    const total = subtotal + deliveryFee;

    const order = await Order.create({
      user:user._id,
      items: orderItems,
      subtotal,
      deliveryFee,
      total,
      paymentMethod,
      paymentStatus: paymentMethod === 'cashOnDelivery' ? 'notRequired' : 'pending',
      customerDetails,
      statusHistory: [{ status: 'pending' }],
    });

    notifyOrderUser({ order, type: 'orderCreated' }).catch((error) => {
      console.error('Order notification failed:', error.message);
    });

    res.status(201).json({ success: true, order });
  } catch (error) {
    const statusCode = error.name === 'ValidationError' ? 400 : 500;
    res.status(statusCode).json({ success: false, message: error.message });
  }
};

// @desc    Get order history for current user
// @route   GET /api/orders/my-orders
// @access  Private
exports.getMyOrders = async (req, res) => {
  try {
    const filter = { user: req.user._id };
    const { skip, limit, page } = getPaginationOptions(req.query);

    const [orders, totalItems] = await Promise.all([
      Order.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('items.menuItem', 'name emoji')
        .populate('transaction'),
      Order.countDocuments(filter),
    ]);

    res.status(200).json({
      success: true,
      count: orders.length,
      pagination: buildPaginationMeta({ totalItems, skip, limit, page }),
      orders,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Track a single order
// @route   GET /api/orders/:id
// @access  Private
exports.getOrderById = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('items.menuItem', 'name emoji')
      .populate('transaction');

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found.' });
    }

    // Users can only see their own orders; admins can see all
    if (order.user.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to view this order.' });
    }

    res.status(200).json({ success: true, order });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
