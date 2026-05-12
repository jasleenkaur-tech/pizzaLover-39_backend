const Notification = require('../models/Notification');
const User = require('../models/User');
const { sendPushNotification } = require('./pushNotifications');

const clients = new Map();

const STATUS_LABELS = {
  pending: 'pending',
  confirmed: 'confirmed',
  preparing: 'being prepared',
  outForDelivery: 'out for delivery',
  delivered: 'delivered',
  cancelled: 'cancelled',
};

const addClient = (userId, res) => {
  const key = userId.toString();
  const userClients = clients.get(key) || new Set();
  userClients.add(res);
  clients.set(key, userClients);

  res.on('close', () => {
    userClients.delete(res);
    if (userClients.size === 0) {
      clients.delete(key);
    }
  });
};

const emitToUser = (userId, event, payload) => {
  const userClients = clients.get(userId.toString());
  if (!userClients) return;

  for (const client of userClients) {
    client.write(`event: ${event}\n`);
    client.write(`data: ${JSON.stringify(payload)}\n\n`);
  }
};

const buildOrderNotification = (type, order) => {
  const shortOrderId = order._id.toString().slice(-6).toUpperCase();
  const statusLabel = STATUS_LABELS[order.status] || order.status;

  if (type === 'orderCreated') {
    return {
      title: 'Order placed successfully',
      message: `Your order #${shortOrderId} has been placed.`,
    };
  }

  if (type === 'paymentConfirmed') {
    return {
      title: 'Payment confirmed',
      message: `Payment received for order #${shortOrderId}. Your order is confirmed.`,
    };
  }

  return {
    title: 'Order update',
    message: `Your order #${shortOrderId} is ${statusLabel}.`,
  };
};

const notifyOrderUser = async ({ order, type }) => {
  const user = await User.findById(order.user);
  if (!user) return null;

  const prefs = user.notificationPreferences || {};
  if (prefs.pushNotifications === false || prefs.orderUpdates === false) {
    return null;
  }

  const content = buildOrderNotification(type, order);
  const notification = await Notification.create({
    user: user._id,
    order: order._id,
    type,
    title: content.title,
    message: content.message,
    data: {
      orderId: order._id.toString(),
      status: order.status,
      paymentStatus: order.paymentStatus,
    },
  });

  const payload = {
    notification,
    order,
  };

  emitToUser(user._id, 'notification', payload);
  emitToUser(user._id, 'order:update', payload);

  await Promise.all(
    (user.pushTokens || []).map(async ({ token }) => {
      try {
        await sendPushNotification({
          token,
          title: content.title,
          body: content.message,
          data: {
            notificationId: notification._id.toString(),
            orderId: order._id.toString(),
            type,
            status: order.status,
          },
        });
      } catch (error) {
        console.error('FCM push failed:', error.body || error.message);
      }
    })
  );

  return notification;
};

module.exports = {
  addClient,
  notifyOrderUser,
};
