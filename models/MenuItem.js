const mongoose = require('mongoose');

const menuItemSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Item name is required'],
      trim: true,
    },
    description: {
      type: String,
      required: [true, 'Description is required'],
      trim: true,
    },
    // Flexible price map: supports regular/medium/large or any size key
    prices: {
      type: Map,
      of: Number,
      required: [true, 'At least one price is required'],
      validate: {
        validator: (map) => map.size > 0,
        message: 'Prices map cannot be empty',
      },
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      enum: [
        'vegPizza',
        'nonVegPizza',
        'burger',
        'pasta',
        'sides',
        'drinks',
        'desserts',
      ],
    },
    isVeg: {
      type: Boolean,
      default: true,
    },
    isBestseller: {
      type: Boolean,
      default: false,
    },
    emoji: {
      type: String,
      default: '🍕',
    },
    isAvailable: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

// Index for fast category queries
menuItemSchema.index({ category: 1, isAvailable: 1 });

module.exports = mongoose.model('MenuItem', menuItemSchema);
