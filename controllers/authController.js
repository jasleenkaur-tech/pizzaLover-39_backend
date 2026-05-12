const jwt = require('jsonwebtoken');
const User = require('../models/User');

const getAdminEmails = () =>
  (process.env.ADMIN_EMAILS || 'admin@pizzalovers39.com')
    .split(',')
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);

const applyConfiguredAdminRole = async (user) => {
  if (!user?.email) return user;

  if (getAdminEmails().includes(user.email.toLowerCase()) && user.role !== 'admin') {
    user.role = 'admin';
    await user.save({ validateBeforeSave: false });
  }

  return user;
};

const cookieOptions = (maxAge) => {
  const isProduction = process.env.NODE_ENV === 'production';

  return {
    httpOnly: true,
    secure: isProduction,
    sameSite: isProduction ? 'none' : 'lax',
    maxAge,
  };
};

const sendTokenResponse = async (user, statusCode, res) => {
  await applyConfiguredAdminRole(user);

  const accessToken = user.generateAccessToken();
  const refreshToken = user.generateRefreshToken();

  user.refresh = refreshToken;
  await user.save({ validateBeforeSave: false });

  res.cookie('accessToken', accessToken, cookieOptions(15 * 60 * 1000));
  res.cookie('refreshToken', refreshToken, cookieOptions(7 * 24 * 60 * 60 * 1000));

  res.status(statusCode).json({
    success: true,
    accessToken,
    refreshToken,
    user: {
      id: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      notificationPreferences: user.notificationPreferences,
    },
  });
};

// @desc    Register new user
// @route   POST /api/auth/signup
// @access  Public
exports.signup = async (req, res) => {
  try {
    const { name, email, password, phone } = req.body;
    console.log('signup data:', req.body);
    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide name, email, and password.',
      });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'Email already registered. Please login.',
      });
    }

    const user = await User.create({ name, email, password, phone });
    await sendTokenResponse(user, 201, res);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getCookieValue = (req, cookieName) => {
  const cookieHeader = req.headers.cookie;
  if (!cookieHeader) return null;

  const cookies = cookieHeader.split(';');
  for (const cookie of cookies) {
    const [name, ...valueParts] = cookie.trim().split('=');
    if (name === cookieName) {
      return decodeURIComponent(valueParts.join('='));
    }
  }

  return null;
};

const getAccessTokenFromRequest = (req) => {
  const authHeader = req.headers.authorization;

  if (authHeader) {
    const [scheme, value] = authHeader.split(' ');

    if (/^Bearer$/i.test(scheme) && value) {
      return value;
    }

    if (!value) {
      return authHeader;
    }
  }

  return getCookieValue(req, 'accessToken') || null;
};

const clearAuthCookies = (res) => {
  const options = cookieOptions(0);

  res.clearCookie('accessToken', options);
  res.clearCookie('refreshToken', options);
};

// @desc    Login user
// @route   POST /api/auth/login
// @access  Public
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    console.log('Login data:', req.body);
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password.',
      });
    }

    const user = await User.findOne({ email }).select('+password');
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.',
      });
    }
    await sendTokenResponse(user, 200, res);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get current logged-in user
// @route   GET /api/auth/me
// @access  Private
exports.getMe = async (req, res) => {
  res.status(200).json({
    success: true,
    user: req.user,
  });
};

// @desc    Refresh access token
// @route   POST /api/auth/refresh
// @access  Public
exports.refreshToken = async (req, res) => {
  try {
    const refreshToken = getCookieValue(req, 'refreshToken') || (req.body && req.body.refreshToken);

    if (!refreshToken) {
      return res.status(401).json({
        success: false,
        message: 'No refresh token provided.',
      });
    }

    const decoded = jwt.verify(
      refreshToken,
      process.env.REFRESH_SECRET || process.env.JWT_SECRET
    );
    const user = await User.findById(decoded.id);

    if (!user || user.refresh !== refreshToken) {
      return res.status(401).json({
        success: false,
        message: 'Invalid refresh token.',
      });
    }

    const newAccessToken = user.generateAccessToken();
    const newRefreshToken = user.generateRefreshToken();
    user.refresh = newRefreshToken;
    await user.save({ validateBeforeSave: false });

    res.cookie('accessToken', newAccessToken, cookieOptions(15 * 60 * 1000));
    res.cookie('refreshToken', newRefreshToken, cookieOptions(7 * 24 * 60 * 60 * 1000));

    res.status(200).json({
      success: true,
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    });
    
  } catch (error) {
    res.status(401).json({
      success: false,
      message: 'Refresh token expired or invalid.',
    });
  }
};

// @desc    Logout user
// @route   POST /api/auth/logout
// @access  Public
exports.logout = async (req, res) => {
  try {
    const accessToken = getAccessTokenFromRequest(req);
    const refreshToken = getCookieValue(req, 'refreshToken') || (req.body && req.body.refreshToken);
    let userId = null;

    if (accessToken) {
      try {
        userId = jwt.verify(accessToken, process.env.JWT_SECRET).id;
      } catch (error) {
        userId = null;
      }
    }

    if (!userId && refreshToken) {
      try {
        userId = jwt.verify(
          refreshToken,
          process.env.REFRESH_SECRET || process.env.JWT_SECRET
        ).id;
      } catch (error) {
        userId = null;
      }
    }

    if (userId) {
      await User.findByIdAndUpdate(userId, { refresh: null });
    }
  } catch (error) {
    console.error('Logout cleanup failed:', error.message);
  } finally {
    clearAuthCookies(res);

    res.status(200).json({
      success: true,
      message: 'Logged out successfully.',
    });
  }
};
