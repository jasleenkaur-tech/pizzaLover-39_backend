/**
 * seed.js - Pizza Lovers 39 Database Seeder
 * Run: npm run seed
 */

const mongoose = require('mongoose');
const dotenv = require('dotenv');
const MenuItem = require('./models/MenuItem');
const User = require('./models/User');

dotenv.config();

const menuItems = [
  {
    name: 'Margherita Classic',
    description: 'Golden baked crust with rich tomato base, fresh mozzarella, and basil',
    prices: { regular: 199, medium: 299, large: 399 },
    category: 'vegPizza',
    isVeg: true,
    isBestseller: true,
    emoji: '🍕',
  },
  {
    name: 'Paneer Tikka Bliss',
    description: 'Tandoori paneer, capsicum, onion, and smoky tikka sauce on herb crust',
    prices: { regular: 249, medium: 349, large: 449 },
    category: 'vegPizza',
    isVeg: true,
    isBestseller: true,
    emoji: '🧀',
  },
  {
    name: 'Garden Harvest',
    description: 'Loaded with baby corn, mushroom, olives, red paprika, and pesto drizzle',
    prices: { regular: 229, medium: 329, large: 429 },
    category: 'vegPizza',
    isVeg: true,
    isBestseller: false,
    emoji: '🥦',
  },
  {
    name: 'Spicy Corn & Jalapeno',
    description: 'Sweet corn, jalapenos, bell peppers, and chipotle sauce - fire level high',
    prices: { regular: 219, medium: 319, large: 419 },
    category: 'vegPizza',
    isVeg: true,
    isBestseller: false,
    emoji: '🌽',
  },
  {
    name: 'Chicken BBQ Loaded',
    description: 'Smoky BBQ chicken, caramelized onions, mozzarella, and BBQ drizzle',
    prices: { regular: 279, medium: 379, large: 499 },
    category: 'nonVegPizza',
    isVeg: false,
    isBestseller: true,
    emoji: '🍗',
  },
  {
    name: 'Pepperoni Inferno',
    description: 'Double pepperoni, spicy sauce, jalapenos, mozzarella blend - our hottest',
    prices: { regular: 299, medium: 399, large: 529 },
    category: 'nonVegPizza',
    isVeg: false,
    isBestseller: false,
    emoji: '🥩',
  },
  {
    name: 'Crispy Veg Burger',
    description: 'Crispy veg patty, lettuce, tomato, cheese slice, and special sauce in a toasted bun',
    prices: { regular: 129 },
    category: 'burger',
    isVeg: true,
    isBestseller: false,
    emoji: '🍔',
  },
  {
    name: 'Zinger Chicken Burger',
    description: 'Spicy fried chicken fillet, coleslaw, pickles, and mayo in a sesame bun',
    prices: { regular: 169 },
    category: 'burger',
    isVeg: false,
    isBestseller: true,
    emoji: '🍔',
  },
  {
    name: 'Arrabbiata Penne',
    description: 'Penne in spicy tomato and garlic sauce with fresh herbs and parmesan',
    prices: { regular: 179 },
    category: 'pasta',
    isVeg: true,
    isBestseller: false,
    emoji: '🍝',
  },
  {
    name: 'Chicken Alfredo',
    description: 'Grilled chicken strips in creamy parmesan Alfredo sauce over fettuccine',
    prices: { regular: 219 },
    category: 'pasta',
    isVeg: false,
    isBestseller: true,
    emoji: '🍝',
  },
  {
    name: 'Garlic Breadsticks (6 pcs)',
    description: 'Buttery garlic breadsticks with herbs, served with marinara dip',
    prices: { regular: 99 },
    category: 'sides',
    isVeg: true,
    isBestseller: false,
    emoji: '🥖',
  },
  {
    name: 'Cheesy Loaded Fries',
    description: 'Crispy fries loaded with cheddar cheese sauce and jalapenos',
    prices: { regular: 129 },
    category: 'sides',
    isVeg: true,
    isBestseller: true,
    emoji: '🍟',
  },
  {
    name: 'Coca-Cola',
    description: 'Chilled Coca-Cola',
    prices: { regular: 49 },
    category: 'drinks',
    isVeg: true,
    isBestseller: false,
    emoji: '🥤',
  },
  {
    name: 'Mango Lassi',
    description: 'Thick and creamy mango yogurt lassi - house special',
    prices: { regular: 79 },
    category: 'drinks',
    isVeg: true,
    isBestseller: true,
    emoji: '🥭',
  },
];

const adminUser = {
  name: 'Pizza Admin',
  email: 'admin@pizzalovers39.com',
  password: 'Admin@123',
  phone: '9999999999',
  role: 'admin',
};

const seedDB = async () => {
  try {
    if (!process.env.MONGO_URI || process.env.MONGO_URI.includes('cluster0.xxxxx')) {
      throw new Error('Set a real MONGO_URI in .env before running npm run seed');
    }

    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB for seeding...');

    await MenuItem.deleteMany();
    await User.deleteMany({ role: 'admin' });
    console.log('Cleared existing menu items and admin users.');

    const created = await MenuItem.insertMany(menuItems);
    console.log(`Inserted ${created.length} menu items.`);

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
