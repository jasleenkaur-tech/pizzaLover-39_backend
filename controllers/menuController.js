const MenuItem = require('../models/MenuItem');
const { getPaginationOptions, buildPaginationMeta } = require('../utils/pagination');

// @desc    Get all menu items grouped by category
// @route   GET /api/menu
// @access  Public
exports.getMenu = async (req, res) => {
  try {
    const filter = { isAvailable: true };
    const { skip, limit, page } = getPaginationOptions(req.query);

    const [items, totalItems] = await Promise.all([
      MenuItem.find(filter)
        .sort({ isBestseller: -1, name: 1 })
        .skip(skip)
        .limit(limit),
      MenuItem.countDocuments(filter),
    ]);

    // Group items by category
    const groupedMenu = items.reduce((acc, item) => {
      const category = item.category;
      if (!acc[category]) acc[category] = [];
      acc[category].push(item);
      return acc;
    }, {});

    res.status(200).json({
      success: true,
      totalItems: items.length,
      pagination: buildPaginationMeta({ totalItems, skip, limit, page }),
      menu: groupedMenu,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get single menu item by ID
// @route   GET /api/menu/:id
// @access  Public
exports.getMenuItemById = async (req, res) => {
  try {
    const item = await MenuItem.findById(req.params.id);
    if (!item) {
      return res.status(404).json({ success: false, message: 'Menu item not found.' });
    }
    res.status(200).json({ success: true, item });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Add a new menu item (Admin)
// @route   POST /api/menu
// @access  Private/Admin
exports.addMenuItem = async (req, res) => {
  try {
    const { name, description, prices, category, isVeg, isBestseller, emoji } = req.body;

    if (!name || !description || !prices || !category) {
      return res.status(400).json({
        success: false,
        message: 'Name, description, prices, and category are required.',
      });
    }

    const item = await MenuItem.create({
      name,
      description,
      prices,
      category,
      isVeg,
      isBestseller,
      emoji,
    });

    res.status(201).json({ success: true, item });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Update a menu item (Admin)
// @route   PUT /api/menu/:id
// @access  Private/Admin
exports.updateMenuItem = async (req, res) => {
  try {
    const item = await MenuItem.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!item) {
      return res.status(404).json({ success: false, message: 'Menu item not found.' });
    }
    res.status(200).json({ success: true, item });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Delete a menu item (Admin)
// @route   DELETE /api/menu/:id
// @access  Private/Admin
exports.deleteMenuItem = async (req, res) => {
  try {
    const item = await MenuItem.findByIdAndDelete(req.params.id);
    if (!item) {
      return res.status(404).json({ success: false, message: 'Menu item not found.' });
    }
    res.status(200).json({ success: true, message: 'Menu item deleted successfully.' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
