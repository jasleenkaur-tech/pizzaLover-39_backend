const express = require('express');
const {
  getNotificationSettings,
  updateNotificationSettings,
  registerPushToken,
  unregisterPushToken,
  getNotifications,
  markNotificationRead,
  streamNotifications,
} = require('../controllers/notificationController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);

router.get('/settings', getNotificationSettings);
router.patch('/settings', updateNotificationSettings);
router.post('/push-token', registerPushToken);
router.delete('/push-token', unregisterPushToken);
router.get('/', getNotifications);
router.patch('/:id/read', markNotificationRead);
router.get('/stream', streamNotifications);

module.exports = router;
