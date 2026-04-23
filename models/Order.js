const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  menuItem: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'MenuItem',
    required: true,
  },
  name: { type: String, required: true },  // snapshot at order time
  size: { type: String, required: true },  // e.g., 'regular', 'medium', 'large'
  price: { type: Number, required: true }, // snapshot at order time
  quantity: { type: Number, required: true, min: 1 },
  emoji: { type: String },
});

const customerDetailsSchema = new mongoose.Schema({
  name: { type: String, required: true },
  phone: { type: String, required: true },
  address: { type: String, required: true },
});

const orderSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    items: {
      type: [orderItemSchema],
      validate: {
        validator: (arr) => arr.length > 0,
        message: 'Order must contain at least one item',
      },
    },
    subtotal: { type: Number, required: true },
    deliveryFee: { type: Number, required: true, default: 40 },
    total: { type: Number, required: true },
    paymentMethod: {
      type: String,
      enum: ['cashOnDelivery', 'upi', 'card', 'wallet'],
      required: true,
    },
    status: {
      type: String,
      enum: [
        'pending',
        'confirmed',
        'preparing',
        'outForDelivery',
        'delivered',
        'cancelled',
      ],
      default: 'pending',
    },
    customerDetails: {
      type: customerDetailsSchema,
      required: true,
    },
    statusHistory: [
      {
        status: String,
        changedAt: { type: Date, default: Date.now },
        note: String,
      },
    ],
  },
  { timestamps: true }
);

// Auto-push to statusHistory on status change
orderSchema.pre('save', function (next) {
  if (this.isModified('status')) {
    this.statusHistory.push({ status: this.status });
  }
  next();
});

// Index for fast user order queries
orderSchema.index({ user: 1, createdAt: -1 });
orderSchema.index({ status: 1 });

module.exports = mongoose.model('Order', orderSchema);
