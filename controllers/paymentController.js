const crypto = require('crypto');
const Razorpay = require('razorpay');
const Order = require('../models/Order');
const Transaction = require('../models/Transaction');
const { notifyOrderUser } = require('../utils/notificationService');

const getRazorpay = () => {
  if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
    const error = new Error('Razorpay keys are not configured.');
    error.statusCode = 500;
    throw error;
  }

  return new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET,
  });
};

const canAccessOrder = (order, user) =>
  order.user.toString() === user._id.toString() || user.role === 'admin';

// @desc    Create a Razorpay order for an existing app order
// @route   POST /api/payments/create-order
// @access  Private
exports.createRazorpayOrder = async (req, res) => {
  try {
    const { orderId } = req.body;

    if (!orderId) {
      return res.status(400).json({ success: false, message: 'orderId is required.' });
    }

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found.' });
    }
    if (!canAccessOrder(order, req.user)) {
      return res.status(403).json({ success: false, message: 'Not authorized to pay for this order.' });
    }
    if (order.paymentMethod === 'cashOnDelivery') {
      return res.status(400).json({ success: false, message: 'Online payment is not required for cash orders.' });
    }
    if (order.paymentStatus === 'paid') {
      return res.status(400).json({ success: false, message: 'This order is already paid.' });
    }

    const amountInPaise = Math.round(order.total * 100);
    const receipt = `order_${order._id.toString().slice(-20)}`;
    const razorpayOrder = await getRazorpay().orders.create({
      amount: amountInPaise,
      currency: 'INR',
      receipt,
      notes: {
        appOrderId: order._id.toString(),
        userId: req.user._id.toString(),
      },
    });

    const transaction = await Transaction.create({
      order: order._id,
      user: req.user._id,
      razorpayOrderId: razorpayOrder.id,
      amount: amountInPaise,
      currency: razorpayOrder.currency,
      status: 'created',
      receipt,
      notes: {
        appOrderId: order._id.toString(),
        userId: req.user._id.toString(),
      },
    });

    order.transaction = transaction._id;
    order.paymentStatus = 'pending';
    await order.save();

    res.status(201).json({
      success: true,
      key: process.env.RAZORPAY_KEY_ID,
      id: razorpayOrder.id,
      orderId: razorpayOrder.id,
      razorpay_order_id: razorpayOrder.id,
      razorpayOrderId: razorpayOrder.id,
      amount: razorpayOrder.amount,
      currency: razorpayOrder.currency,
      receipt: razorpayOrder.receipt,
      order,
      transaction,
      razorpayOrder,
    });
  } catch (error) {
    const statusCode = error.statusCode || error.status || 500;
    const razorpayError = error.error || error;

    console.error('Create Razorpay order failed:', {
      statusCode,
      message: razorpayError.description || razorpayError.message || error.message,
      code: razorpayError.code,
      reason: razorpayError.reason,
      field: razorpayError.field,
    });

    res.status(statusCode).json({
      success: false,
      message: razorpayError.description || error.message || 'Failed to create Razorpay order.',
    });
  }
};

// @desc    Verify Razorpay payment and store payment details
// @route   POST /api/payments/verify
// @access  Private
exports.verifyRazorpayPayment = async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({
        success: false,
        message: 'razorpay_order_id, razorpay_payment_id, and razorpay_signature are required.',
      });
    }

    const transaction = await Transaction.findOne({ razorpayOrderId: razorpay_order_id });
    if (!transaction) {
      return res.status(404).json({ success: false, message: 'Transaction not found.' });
    }

    const order = await Order.findById(transaction.order);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found.' });
    }
    if (!canAccessOrder(order, req.user)) {
      return res.status(403).json({ success: false, message: 'Not authorized to verify this payment.' });
    }

    const generatedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(`${razorpay_order_id}|${razorpay_payment_id}`)
      .digest('hex');

    if (generatedSignature !== razorpay_signature) {
      transaction.status = 'failed';
      transaction.failureReason = 'Invalid Razorpay signature';
      transaction.razorpayPaymentId = razorpay_payment_id;
      transaction.razorpaySignature = razorpay_signature;
      order.paymentStatus = 'failed';

      await Promise.all([transaction.save(), order.save()]);

      return res.status(400).json({ success: false, message: 'Payment verification failed.' });
    }

    transaction.status = 'paid';
    transaction.razorpayPaymentId = razorpay_payment_id;
    transaction.razorpaySignature = razorpay_signature;
    transaction.paidAt = new Date();

    order.paymentStatus = 'paid';
    order.transaction = transaction._id;
    if (order.status === 'pending') {
      order.status = 'confirmed';
    }

    await Promise.all([transaction.save(), order.save()]);

    notifyOrderUser({ order, type: 'paymentConfirmed' }).catch((error) => {
      console.error('Payment notification failed:', error.message);
    });

    res.status(200).json({
      success: true,
      message: 'Payment verified successfully.',
      order,
      transaction,
    });
  } catch (error) {
    res.status(error.statusCode || 500).json({ success: false, message: error.message });
  }
};

// @desc    Get stored payment attempts for an order
// @route   GET /api/payments/order/:orderId
// @access  Private
exports.getOrderTransactions = async (req, res) => {
  try {
    const order = await Order.findById(req.params.orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found.' });
    }
    if (!canAccessOrder(order, req.user)) {
      return res.status(403).json({ success: false, message: 'Not authorized to view these payments.' });
    }

    const transactions = await Transaction.find({ order: order._id }).sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: transactions.length,
      transactions,
    });
  } catch (error) {
    res.status(error.statusCode || 500).json({ success: false, message: error.message });
  }
};
