const express = require('express');
const router = express.Router();
const blockingController = require('../controllers/blocking.controller');

// Bloquear usuario
router.post('/block', blockingController.blockUser);

// Desbloquear usuario
router.post('/unblock', blockingController.unblockUser);

// Obtener lista de usuarios bloqueados
router.get('/blocked', blockingController.getBlockedUsers);

// Verificar si un usuario está bloqueado
router.get('/is-blocked/:id_otro_usuario', blockingController.isUserBlocked);

// Actualizar última conexión
router.put('/last-seen', blockingController.updateLastSeen);

module.exports = router;
