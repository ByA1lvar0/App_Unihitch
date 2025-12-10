const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notification.controller');

router.get('/:userId', notificationController.getNotifications);
router.post('/', notificationController.createNotification);
router.put('/:id/read', notificationController.markAsRead);
router.put('/:userId/read-all', notificationController.markAllAsRead);

module.exports = router;
