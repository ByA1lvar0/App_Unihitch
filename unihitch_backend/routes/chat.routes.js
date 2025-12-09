const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chat.controller');
const { validateChatAccess, validateMessageAccess } = require('../middleware/chat-validation.middleware');
const authMiddleware = require('../middleware/auth.middleware');

// Aplicar middleware de autenticación a todas las rutas de chat
router.use(authMiddleware);

// Crear chat (con validación de acceso)
router.post('/chats', validateChatAccess, chatController.createChat);

// Obtener chats del usuario
router.get('/chats/:userId', chatController.getChats);

// Obtener contador de no leídos
router.get('/chats/:userId/unread-count', chatController.getUnreadCount);

// Obtener mensajes de un chat
router.get('/chats/:chatId/messages', chatController.getMessages);

// Enviar mensaje (con validación)
router.post('/messages', validateMessageAccess, chatController.sendMessage);

// Marcar como leído
router.put('/chats/:chatId/read/:userId', chatController.markAsRead);

// Contador de mensajes no leídos
router.get('/messages/unread-count/:userId', chatController.getUnreadMessagesCount);

module.exports = router;

