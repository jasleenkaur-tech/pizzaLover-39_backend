const jwt = require('jsonwebtoken');
const User = require('../models/User');

const getAdminEmails = () =>
  (process.env.ADMIN_EMAILS || 'admin@pizzalovers39.com')
    .split(',')
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);

const accessCookieOptions = () => {
  const isProduction = process.env.NODE_ENV === 'production';

  return {
    httpOnly: true,
    secure: isProduction,
    sameSite: isProduction ? 'none' : 'lax',
    maxAge: 15 * 60 * 1000,
  };
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

const getTokenFromRequest = (req) => {
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

  return (
    req.headers['x-auth-token'] ||
    req.headers.token ||
    req.query.token ||
    req.query.accessToken ||
    getCookieValue(req, 'accessToken') ||
    null
  );
};

const verifyAccessToken = async (token) => {
  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  return User.findById(decoded.id).select('-password');
};

const refreshAccessTokenFromCookie = async (req, res) => {
  const refreshToken = getCookieValue(req, 'refreshToken');
  if (!refreshToken) return null;

  const decoded = jwt.verify(
    refreshToken,
    process.env.REFRESH_SECRET || process.env.JWT_SECRET
  );
  const user = await User.findById(decoded.id).select('-password');
  if (!user || user.refresh !== refreshToken) return null;

  const accessToken = user.generateAccessToken();
  res.cookie('accessToken', accessToken, accessCookieOptions());
  res.set('x-access-token', accessToken);

  return user;
};

// Protect routes - verify JWT
exports.protect = async (req, res, next) => {
  try {
    const token = getTokenFromRequest(req);

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized. No token provided.',
      });
    }

    req.user = await verifyAccessToken(token);

    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'User no longer exists.',
      });
    }

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      try {
        req.user = await refreshAccessTokenFromCookie(req, res);

        if (req.user) {
          return next();
        }
      } catch (refreshError) {
        return res.status(401).json({
          success: false,
          message: 'Not authorized. Please login again.',
        });
      }
    }

    return res.status(401).json({
      success: false,
      message: 'Not authorized. Invalid token.',
    });
  }
};

const getAdminDeniedResponse = (req) => {
  const response = {
    success: false,
    message: 'Access denied. Admins only.',
  };

  if (process.env.NODE_ENV !== 'production') {
    response.user = {
      id: req.user?._id,
      email: req.user?.email,
      role: req.user?.role,
      configuredAdminEmails: getAdminEmails(),
    };
  }

  return response;
};

// Restrict to admin only
exports.adminOnly = async (req, res, next) => {
  if (
    req.user?.email &&
    req.user.role !== 'admin' &&
    getAdminEmails().includes(req.user.email.toLowerCase())
  ) {
    req.user.role = 'admin';
    await User.updateOne({ _id: req.user._id }, { $set: { role: 'admin' } });
  }

  if (req.user.role !== 'admin') {
    console.warn('Admin access denied:', {
      userId: req.user?._id?.toString(),
      email: req.user?.email,
      role: req.user?.role,
      configuredAdminEmails: getAdminEmails(),
    });

    return res.status(403).json(getAdminDeniedResponse(req));
  }
  next();
};
