const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');

router.get('/users/pending', adminController.getPendingUsers);
router.put('/users/:userId/verify', adminController.verifyUser);
router.post('/add-admin', adminController.addAdmin);
router.delete('/users/:userId', adminController.deleteUser);
router.post('/change-university', adminController.changeUniversity);
router.get('/dashboard-stats', adminController.getDashboardStats);
router.put('/users/:userId/toggle-status', adminController.toggleUserStatus);
router.get('/trips', adminController.getAllTrips);

module.exports = router;
