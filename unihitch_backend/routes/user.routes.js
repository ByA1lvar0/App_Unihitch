const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');

router.put('/:id', userController.updateUser);
router.get('/search', userController.searchUsers);
router.put('/:id/emergency-contact', userController.updateEmergencyContact);
router.get('/:id', userController.getUser);
router.get('/', userController.getUsers); // Original /api/usuarios

module.exports = router;
