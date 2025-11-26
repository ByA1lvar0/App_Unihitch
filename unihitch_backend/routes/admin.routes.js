const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');

router.get('/pending-users', adminController.getPendingUsers);
router.post('/verify-user/:userId', adminController.verifyUser);
router.post('/add-admin', adminController.addAdmin);
// router.get('/usuarios', adminController.getUsers); // Moved to user.routes.js
// Wait, original was /api/usuarios (not /api/admin/usuarios).
// I should probably mount this at /api/admin and update frontend, OR mount at /api and define paths.
// Let's mount at /api/admin for most, but /api/usuarios is tricky.
// I'll stick to defining relative paths here assuming mount at /api/admin, but for /api/usuarios I might need a separate route or just accept the change.
// Actually, `getUsers` is used for "Obtener todos los usuarios (para buscar y añadir)".
// I'll keep it under admin routes.

router.delete('/delete-user/:userId', adminController.deleteUser);
router.post('/change-university', adminController.changeUniversity);

module.exports = router;
