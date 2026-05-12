const dotenv = require('dotenv');
const mongoose = require('mongoose');
const User = require('../models/User');

dotenv.config();

const email = (process.argv[2] || process.env.ADMIN_EMAILS || 'admin@pizzalovers39.com')
  .split(',')[0]
  .trim()
  .toLowerCase();
const password = process.argv[3] || 'Admin@123';

const run = async () => {
  if (!process.env.MONGO_URI) {
    throw new Error('MONGO_URI is missing.');
  }

  await mongoose.connect(process.env.MONGO_URI);

  let user = await User.findOneAndUpdate(
    { email },
    { $set: { role: 'admin' } },
    { new: true }
  );

  if (!user) {
    user = await User.create({
      name: 'Restaurant Admin',
      email,
      password,
      phone: '9878394950',
      role: 'admin',
    });

    console.log(`Admin user created for ${user.email}.`);
  } else {
    console.log(`Admin role confirmed for ${user.email}.`);
  }

  await mongoose.connection.close();
};

run()
  .then(() => process.exit(0))
  .catch(async (error) => {
    console.error(error.message);

    if (mongoose.connection.readyState !== 0) {
      await mongoose.connection.close();
    }

    process.exit(1);
  });
