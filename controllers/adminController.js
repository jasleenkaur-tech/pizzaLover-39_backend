const Order = require('../models/Order');
const User = require('../models/User');

const VALID_STATUSES = ['pending', 'confirmed', 'preparing', 'outForDelivery', 'delivered', 'cancelled'];

// @desc    Get all orders (with optional status filter)
// @route   GET /api/admin/orders
// @access  Private/Admin
exports.getAllOrders = async (req, res) => {
  try {
    const filter = {};
    if (req.query.status) {
      if (!VALID_STATUSES.includes(req.query.status)) {
        return res.status(400).json({ success: false, message: 'Invalid status filter.' });
      }
      filter.status = req.query.status;
    }

    const orders = await Order.find(filter)
      .sort({ createdAt: -1 })
      .populate('user', 'name email phone')
      .populate('items.menuItem', 'name');

    res.status(200).json({ success: true, count: orders.length, orders });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Update order status
// @route   PATCH /api/admin/orders/:id/status
// @access  Private/Admin
exports.updateOrderStatus = async (req, res) => {
  try {
    const { status, note } = req.body;

    if (!status) {
      return res.status(400).json({ success: false, message: 'Status is required.' });
    }
    if (!VALID_STATUSES.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Must be one of: ${VALID_STATUSES.join(', ')}`,
      });
    }

    const order = await Order.findById(req.params._id);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found.' });
    }

    if (order.status === 'delivered' || order.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: `Cannot update a ${order.status} order.`,
      });
    }

    order.status = status;
    if (note) {
      order.statusHistory[order.statusHistory.length - 1].note = note;
    }

    await order.save();

    res.status(200).json({ success: true, message: `Order status updated to "${status}".`, order });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get dashboard stats
// @route   GET /api/admin/stats
// @access  Private/Admin
exports.getDashboardStats = async (req, res) => {
  try {
    const [totalOrders, totalUsers, ordersByStatus, revenueData] = await Promise.all([
      Order.countDocuments(),
      User.countDocuments({ role: 'user' }),
      Order.aggregate([{ $group: { _id: '$status', count: { $sum: 1 } } }]),
      Order.aggregate([
        { $match: { status: { $ne: 'cancelled' } } },
        { $group: { _id: null, totalRevenue: { $sum: '$total' }, avgOrderValue: { $avg: '$total' } } },
      ]),
    ]);

    res.status(200).json({
      success: true,
      stats: {
        totalOrders,
        totalUsers,
        totalRevenue: revenueData[0]?.totalRevenue || 0,
        avgOrderValue: Math.round(revenueData[0]?.avgOrderValue || 0),
        ordersByStatus: ordersByStatus.reduce((acc, s) => {
          acc[s._id] = s.count;
          return acc;
        }, {}),
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
