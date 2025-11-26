const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chat.controller');

router.get('/:userId', chatController.getChats);
router.get('/:userId/unread-count', chatController.getUnreadCount);
router.post('/', chatController.createChat);
router.get('/:chatId/messages', chatController.getMessages);
// Note: Original route was /api/messages for sending message, but logically it belongs to chat.
// I will keep it separate or group it.
// The original server.js had:
// app.post('/api/messages', ...)
// app.put('/api/chats/:chatId/read/:userId', ...)
// app.get('/api/messages/unread-count/:userId', ...)

// I will map them here but I need to be careful with mounting.
// If I mount this at /api/chats, then /api/messages won't work.
// I should probably create a separate route file for messages or handle it in server.js routing.
// Or I can just define the paths here relative to /api if I mount at /api.
// Let's assume I mount at /api.

router.get('/chats/:userId', chatController.getChats);
router.get('/chats/:userId/unread-count', chatController.getUnreadCount);
router.post('/chats', chatController.createChat);
router.get('/chats/:chatId/messages', chatController.getMessages);
router.post('/messages', chatController.sendMessage);
router.put('/chats/:chatId/read/:userId', chatController.markAsRead);
router.get('/messages/unread-count/:userId', chatController.getUnreadMessagesCount);

module.exports = router;
