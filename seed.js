/**
 * seed.js - Pizza Lovers 39 Database Seeder
 * Run: npm run seed
 */

const mongoose = require('mongoose');
const dotenv = require('dotenv');
const MenuItem = require('./models/MenuItem');
const User = require('./models/User');

dotenv.config();

const rawMenuItems = [
  { name: 'Margherita', description: 'Classic tomato sauce with cheese', prices: { regular: 100, medium: 220, large: 350 }, category: 'vegPizza', subCategory: 'Silver', emoji: '🍕', isBestseller: true },
  { name: 'Mushroom Loaded', description: 'Loaded with fresh mushrooms', prices: { regular: 120, medium: 250, large: 380 }, category: 'vegPizza', subCategory: 'Silver', emoji: '🍄' },
  { name: 'Paneer Loaded', description: 'Loaded with fresh paneer', prices: { regular: 120, medium: 250, large: 380 }, category: 'vegPizza', subCategory: 'Silver', emoji: '🧀' },
  { name: 'Veg Crunch', description: 'Onion + Capsicum + Paneer', prices: { regular: 120, medium: 250, large: 380 }, category: 'vegPizza', subCategory: 'Silver', emoji: '🥗' },
  { name: 'Spring Fling', description: 'Capsicum + Corn + Paneer', prices: { regular: 120, medium: 250, large: 380 }, category: 'vegPizza', subCategory: 'Silver', emoji: '🌽' },
  { name: 'Country Side', description: 'Mushroom + Corn + Olives', prices: { regular: 120, medium: 250, large: 380 }, category: 'vegPizza', subCategory: 'Silver', emoji: '🫒' },
  { name: 'Garden Delight', description: 'Onion + Capsicum + Tomatoes', prices: { regular: 120, medium: 250, large: 380 }, category: 'vegPizza', subCategory: 'Silver', emoji: '🍅' },
  { name: 'Farm House', description: 'Onion + Capsicum + Tomato + Mushroom', prices: { regular: 140, medium: 300, large: 430 }, category: 'vegPizza', subCategory: 'Gold', emoji: '🏡', isBestseller: true },
  { name: 'Veggie Lover', description: 'Onion + Olives + Capsicum + Paneer', prices: { regular: 140, medium: 300, large: 430 }, category: 'vegPizza', subCategory: 'Gold', emoji: '🥬' },
  { name: 'Burn To Hell', description: 'Capsicum + Jalapeno + Mushroom + Red Paprika', prices: { regular: 140, medium: 300, large: 430 }, category: 'vegPizza', subCategory: 'Gold', emoji: '🌶️' },
  { name: 'Country Special', description: 'Onion + Capsicum + Corn + Paneer', prices: { regular: 140, medium: 300, large: 430 }, category: 'vegPizza', subCategory: 'Gold', emoji: '⭐' },
  { name: 'Paneer Blast', description: 'Onion + Corn + Extra Paneer + Mushroom + Red Paprika', prices: { regular: 160, medium: 380, large: 500 }, category: 'vegPizza', subCategory: 'Platinum', emoji: '💥' },
  { name: 'Hot Passion', description: 'Onion + Capsicum + Jalapeno + Red Paprika + Hot Sauce', prices: { regular: 160, medium: 380, large: 500 }, category: 'vegPizza', subCategory: 'Platinum', emoji: '🔥', isBestseller: true },
  { name: 'Peri Peri Veg', description: 'Onion + Capsicum + Olives + Mushroom + Paneer + Peri Peri Sauce', prices: { regular: 160, medium: 380, large: 500 }, category: 'vegPizza', subCategory: 'Platinum', emoji: '🌿' },
  { name: 'Tandoori Veg', description: 'Onion + Corn + Mushroom + Paneer + Jalapeno + Tandoori Sauce', prices: { regular: 160, medium: 380, large: 500 }, category: 'vegPizza', subCategory: 'Platinum', emoji: '🫶' },
  { name: 'Achari Veg', description: 'Capsicum + Corn + Paneer + Red Paprika + Tomato + Achari Sauce', prices: { regular: 160, medium: 380, large: 500 }, category: 'vegPizza', subCategory: 'Platinum', emoji: '🥒' },

  { name: 'Special Veg Pasta Pizza', description: 'Onion + Capsicum + Corn + Olives + Mushroom + Pasta + Cheese', prices: { regular: 190, medium: 390, large: 550 }, category: 'special', subCategory: 'Special', emoji: '🍝' },
  { name: 'Heart Special', description: 'Onion + Capsicum + Olives + Paneer + Mushroom + Extra Cheese', prices: { regular: 220, medium: 460, large: 600 }, category: 'special', subCategory: 'Lover Special', emoji: '❤️', isBestseller: true },
  { name: 'Ultimate Pizza', description: 'Onion + Capsicum + Corn + Paneer + Mushroom + Olives + Red Paprika + Jalapeno + Extra Cheese', prices: { regular: 240, medium: 480, large: 650 }, category: 'special', subCategory: 'Ultimate', emoji: '👑', isBestseller: true },
  { name: 'Double Mania - Onion+Paneer', description: 'Onion + Paneer', prices: { regular: 89, medium: 200, large: 320 }, category: 'special', subCategory: 'Mania', emoji: '🎯' },
  { name: 'Double Mania - Onion+Capsicum', description: 'Onion + Capsicum', prices: { regular: 89, medium: 200, large: 320 }, category: 'special', subCategory: 'Mania', emoji: '🎯' },
  { name: 'Double Mania - Corn+Tomato', description: 'Corn + Tomato', prices: { regular: 89, medium: 200, large: 320 }, category: 'special', subCategory: 'Mania', emoji: '🎯' },
  { name: 'Double Mania - Jalapeno+Corn', description: 'Jalapeno + Corn', prices: { regular: 89, medium: 200, large: 320 }, category: 'special', subCategory: 'Mania', emoji: '🎯' },
  { name: 'Double Pizza Mania Combo', description: 'Special combo deal', price: 340, category: 'special', subCategory: 'Mania', emoji: '🎉' },
  { name: 'Single Pizza Mania Combo', description: 'Single pizza combo', price: 260, category: 'special', subCategory: 'Mania', emoji: '🎊' },
  { name: 'Tomato Pizza Mania', description: 'Single topping tomato', price: 69, category: 'special', subCategory: 'Mania', emoji: '🍅' },
  { name: 'Onion Pizza Mania', description: 'Single topping onion', price: 69, category: 'special', subCategory: 'Mania', emoji: '🧅' },
  { name: 'Capsicum Pizza Mania', description: 'Single topping capsicum', price: 69, category: 'special', subCategory: 'Mania', emoji: '🫑' },
  { name: 'Corn Pizza Mania', description: 'Single topping corn', price: 69, category: 'special', subCategory: 'Mania', emoji: '🌽' },

  { name: 'Aloo Tikki Burger', price: 40, category: 'burger', emoji: '🍔' },
  { name: 'Spicy Aloo Tikki Burger', price: 50, category: 'burger', emoji: '🌶️' },
  { name: 'Crunchy Burger', price: 60, category: 'burger', emoji: '🍔' },
  { name: 'Cheese Aloo Tikki Burger', price: 60, category: 'burger', emoji: '🧀', isBestseller: true },
  { name: 'Veg Burger', price: 60, category: 'burger', emoji: '🥗' },
  { name: 'Spicy Veg Burger', price: 70, category: 'burger', emoji: '🌶️' },
  { name: 'Cheese Veg Burger', price: 80, category: 'burger', emoji: '🧀' },
  { name: 'Peri Peri Burger', price: 80, category: 'burger', emoji: '🔥' },
  { name: 'Cheese Peri Peri Burger', price: 90, category: 'burger', emoji: '🔥', isBestseller: true },
  { name: 'Burger of King', price: 120, category: 'burger', emoji: '👑' },

  { name: 'White Sauce Pasta', prices: { regular: 80, large: 150 }, category: 'pasta', emoji: '🍝' },
  { name: 'Red Sauce Pasta', prices: { regular: 80, large: 150 }, category: 'pasta', emoji: '🍝', isBestseller: true },
  { name: 'Mix Sauce Pasta', prices: { regular: 80, large: 150 }, category: 'pasta', emoji: '🍝' },
  { name: 'Tandoori Pasta', prices: { regular: 100, large: 190 }, category: 'pasta', emoji: '🔥' },
  { name: 'Ultimate Pasta', prices: { regular: 120, large: 230 }, category: 'pasta', emoji: '👑' },

  { name: 'Hot Coffee', price: 40, category: 'shakes', emoji: '☕' },
  { name: 'Cold Coffee', price: 80, category: 'shakes', emoji: '🧋' },
  { name: 'Chocolate Cold Coffee', price: 80, category: 'shakes', emoji: '🍫', isBestseller: true },
  { name: 'Vanilla Shake', price: 80, category: 'shakes', emoji: '🍦' },
  { name: 'Strawberry Shake', price: 80, category: 'shakes', emoji: '🍓' },
  { name: 'Butter Scotch Shake', price: 80, category: 'shakes', emoji: '🧁' },
  { name: 'Oreo Shake', price: 80, category: 'shakes', emoji: '🍪' },
  { name: 'Chocolate Shake', price: 80, category: 'shakes', emoji: '🍫' },
  { name: 'Mojito', price: 80, category: 'shakes', emoji: '🍹' },
  { name: 'Masala Lemon', price: 80, category: 'shakes', emoji: '🍋' },
  { name: 'Blueberry Shake', price: 80, category: 'shakes', emoji: '🫐' },
  { name: 'Choco Lava Cake', price: 70, category: 'shakes', emoji: '🎂', isBestseller: true },

  { name: 'Veg Wrap', description: 'Onion + Capsicum + Corn', price: 60, category: 'wraps', emoji: '🌯' },
  { name: 'Aloo Tikki Wrap', description: 'Onion + Aloo Tikki + Corn', price: 70, category: 'wraps', emoji: '🌯' },
  { name: 'Paneer Wrap', description: 'Onion + Corn + Paneer', price: 80, category: 'wraps', emoji: '🌯' },
  { name: 'Farmhouse Wrap', description: 'Onion + Corn + Tomato + Mushroom', price: 90, category: 'wraps', emoji: '🌯' },
  { name: 'City Special Wrap', description: 'Onion + Capsicum + Paneer + Mushroom', price: 100, category: 'wraps', emoji: '⭐', isBestseller: true },
  { name: 'Cheese Wrap', description: 'Onion + Paneer + Mushroom + Corn + Cheese', price: 120, category: 'wraps', emoji: '🧀' },
  { name: 'Ultimate Wrap', description: 'Onion + Capsicum + Corn + Paneer Tikki + Mushroom + Cheese', price: 150, category: 'wraps', emoji: '👑' },

  { name: 'Plain Fries', prices: { regular: 40, medium: 60, large: 110 }, category: 'fries', emoji: '🍟' },
  { name: 'Peri Peri Fries', prices: { regular: 50, medium: 80, large: 150 }, category: 'fries', emoji: '🌶️', isBestseller: true },
  { name: 'Creamy Fries', prices: { regular: 50, medium: 80, large: 150 }, category: 'fries', emoji: '🍟' },
  { name: 'Tandoori Fries', prices: { regular: 50, medium: 80, large: 150 }, category: 'fries', emoji: '🔥' },
  { name: 'Mix Sauce Fries', prices: { regular: 60, medium: 90, large: 170 }, category: 'fries', emoji: '🍟' },
  { name: 'Masala Fries', prices: { regular: 50, medium: 80, large: 150 }, category: 'fries', emoji: '✨' },

  { name: 'Cold Sandwich', price: 50, category: 'sandwich', emoji: '🥪' },
  { name: 'Veg Grilled Sandwich', description: 'Onion + Corn + Capsicum', price: 60, category: 'sandwich', emoji: '🥪' },
  { name: 'Hot Sandwich', description: 'Onion + Corn + Jalapeno + Hot Sauce', price: 70, category: 'sandwich', emoji: '🌶️' },
  { name: 'Paneer Grilled Sandwich', description: 'Onion + Corn + Paneer', price: 80, category: 'sandwich', emoji: '🥪', isBestseller: true },
  { name: 'Farmhouse Sandwich', description: 'Onion + Corn + Tomato + Mushroom', price: 90, category: 'sandwich', emoji: '🏡' },
  { name: 'City Special Sandwich', description: 'Onion + Capsicum + Paneer + Mushroom', price: 100, category: 'sandwich', emoji: '⭐' },
  { name: 'Cheese Sandwich', description: 'Onion + Paneer + Mushroom + Corn + Cheese', price: 110, category: 'sandwich', emoji: '🧀' },
  { name: 'Ultimate Sandwich', description: 'Onion + Paneer + Mushroom + Corn + Cheese + Peri Peri Sauce', price: 120, category: 'sandwich', emoji: '👑' },

  { name: 'Veg Taco', description: 'Corn + Paneer', price: 80, category: 'tacos', emoji: '🌮' },
  { name: 'Farm Yard Taco', description: 'Onion + Capsicum + Mushroom', price: 90, category: 'tacos', emoji: '🌮' },
  { name: 'City Special Taco', description: 'Onion + Capsicum + Paneer + Mushroom', price: 100, category: 'tacos', emoji: '🌮', isBestseller: true },
  { name: 'Cheese Taco', description: 'Onion + Paneer + Corn + Mushroom + Cheese', price: 120, category: 'tacos', emoji: '🧀' },
  { name: 'Ultimate Taco', description: 'Onion + Corn + Paneer Tikki + Mushroom + Cheese', price: 150, category: 'tacos', emoji: '👑' },

  { name: 'Potato Pops', price: 100, category: 'snacks', emoji: '🥔' },
  { name: 'Veg Fries', price: 100, category: 'snacks', emoji: '🍟' },
  { name: 'Paneer Salad', prices: { regular: 90, large: 170 }, category: 'snacks', emoji: '🥗' },
  { name: 'Crunchy Salad', prices: { regular: 100, large: 190 }, category: 'snacks', emoji: '🥗' },

  { name: 'Cheese Garlic Stick', price: 90, category: 'garlic', emoji: '🧄' },
  { name: 'Stuffed Garlic Bread', description: 'Corn + Jalapeno + Cheese', price: 90, category: 'garlic', emoji: '🍞', isBestseller: true },
  { name: 'Ultimate Stuffed Garlic Bread', description: 'Corn + Paneer + Extra Cheese', price: 110, category: 'garlic', emoji: '👑' },
  { name: 'Veg Loaded Garlic Bread', description: 'Onion + Capsicum + Red Paprika + Corn + Cheese', price: 130, category: 'garlic', emoji: '🥦' },
  { name: 'Zingy Parcel', price: 50, category: 'garlic', emoji: '📦' },
  { name: 'Paneer Zingy Parcel', price: 70, category: 'garlic', emoji: '📦' },

  { name: 'Meals-1', description: '1 Cheese Aloo Tikki Burger + Plain Fries Small + 250ml Coke', price: 110, category: 'meals', emoji: '🎁' },
  { name: 'Meals-2', description: 'Veg Crunch Small Pizza + Cheese Taco + 250ml Coke', price: 240, category: 'meals', emoji: '🎁', isBestseller: true },
  { name: 'Meals-3', description: 'Spring Fling Small Pizza + Pasta + Oreo Shake', price: 260, category: 'meals', emoji: '🎁' },
  { name: 'Meals-4', description: 'Veg Crunch Medium Pizza + Ultimate Stuffed Garlic Bread + Coke', price: 370, category: 'meals', emoji: '🎁' },
  { name: 'Meals-5', description: 'Peri-Peri Veg Large Pizza + Choco Lava Cake + Paneer Grill Sandwich + Coke 2 Ltr', price: 680, category: 'meals', emoji: '🎁', isBestseller: true },
];

const menuItems = rawMenuItems.map((item) => {
  const prices = item.prices || { regular: item.price };

  return {
    name: item.name,
    description: item.description || `${item.name} from Pizza Lovers 39`,
    prices,
    category: item.category,
    subCategory: item.subCategory,
    isVeg: item.isVeg ?? true,
    isBestseller: item.isBestseller ?? false,
    emoji: item.emoji || '🍕',
    isAvailable: item.isAvailable ?? true,
  };
});

const adminUser = {
  name: 'Restaurant Admin',
  email: 'admin@pizzalovers39.com',
  password: 'Admin@123',
  phone: '9878394950',
  role: 'admin',
};

const seedDB = async () => {
  try {
    if (!process.env.MONGO_URI || process.env.MONGO_URI.includes('cluster0.xxxxx')) {
      throw new Error('Set a real MONGO_URI in .env before running npm run seed');
    }

    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB for seeding...');

    await MenuItem.deleteMany({});
    await User.deleteMany({});
    console.log('Cleared existing menu items and users.');

    const createdMenuItems = await MenuItem.insertMany(menuItems);
    console.log(`${createdMenuItems.length} menu items seeded.`);

    await User.create(adminUser);
    console.log(`Admin user created: ${adminUser.email} / ${adminUser.password}`);

    console.log('Database seeded successfully.');
    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error('Seeding failed:', error.message);

    if (error.message.includes('querySrv ECONNREFUSED')) {
      console.error(
        'The MongoDB SRV DNS lookup failed. If .env is correct, switch networks or use a public DNS server like 8.8.8.8 or 1.1.1.1.'
      );
    }

    if (mongoose.connection.readyState !== 0) {
      await mongoose.connection.close();
    }

    process.exit(1);
  }
};

seedDB();
