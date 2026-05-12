const Notification = require('../models/Notification');
const User = require('../models/User');
const { addClient } = require('../utils/notificationService');
const { getPaginationOptions, buildPaginationMeta } = require('../utils/pagination');

exports.getNotificationSettings = async (req, res) => {
  res.status(200).json({
    success: true,
    notificationPreferences: req.user.notificationPreferences || {
      pushNotifications: true,
      orderUpdates: true,
    },
    pushTokens: (req.user.pushTokens || []).map(({ platform, lastUsedAt }) => ({
      platform,
      lastUsedAt,
    })),
  });
};

exports.updateNotificationSettings = async (req, res) => {
  try {
    const allowedKeys = ['pushNotifications', 'orderUpdates'];
    const updates = {};

    for (const key of allowedKeys) {
      if (typeof req.body[key] === 'boolean') {
        updates[`notificationPreferences.${key}`] = req.body[key];
      }
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Send pushNotifications or orderUpdates as a boolean.',
      });
    }

    const user = await User.findByIdAndUpdate(req.user._id, { $set: updates }, { new: true });

    res.status(200).json({
      success: true,
      notificationPreferences: user.notificationPreferences,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.registerPushToken = async (req, res) => {
  try {
    const { token, platform = 'unknown' } = req.body;

    if (!token) {
      return res.status(400).json({ success: false, message: 'token is required.' });
    }

    if (!['android', 'ios', 'web', 'unknown'].includes(platform)) {
      return res.status(400).json({ success: false, message: 'Invalid platform.' });
    }

    await User.updateOne(
      { _id: req.user._id },
      {
        $pull: {
          pushTokens: { token },
        },
      }
    );

    const user = await User.findByIdAndUpdate(
      req.user._id,
      {
        $push: {
          pushTokens: {
            token,
            platform,
            lastUsedAt: new Date(),
          },
        },
      },
      { new: true }
    );

    res.status(200).json({
      success: true,
      pushTokens: user.pushTokens.map(({ platform: tokenPlatform, lastUsedAt }) => ({
        platform: tokenPlatform,
        lastUsedAt,
      })),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.unregisterPushToken = async (req, res) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({ success: false, message: 'token is required.' });
    }

    await User.updateOne(
      { _id: req.user._id },
      {
        $pull: {
          pushTokens: { token },
        },
      }
    );

    res.status(200).json({ success: true, message: 'Push token removed.' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getNotifications = async (req, res) => {
  try {
    const { skip, limit, page } = getPaginationOptions(req.query);

    const [notifications, totalItems] = await Promise.all([
      Notification.find({ user: req.user._id }).sort({ createdAt: -1 }).skip(skip).limit(limit),
      Notification.countDocuments({ user: req.user._id }),
    ]);

    res.status(200).json({
      success: true,
      count: notifications.length,
      pagination: buildPaginationMeta({ totalItems, skip, limit, page }),
      notifications,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.markNotificationRead = async (req, res) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      { readAt: new Date() },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found.' });
    }

    res.status(200).json({ success: true, notification });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.streamNotifications = (req, res) => {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache, no-transform',
    Connection: 'keep-alive',
    'X-Accel-Buffering': 'no',
  });
  res.write('event: connected\n');
  res.write(`data: ${JSON.stringify({ success: true })}\n\n`);

  const heartbeat = setInterval(() => {
    res.write('event: ping\n');
    res.write(`data: ${JSON.stringify({ at: new Date().toISOString() })}\n\n`);
  }, 25000);

  addClient(req.user._id, res);

  res.on('close', () => {
    clearInterval(heartbeat);
  });
};
