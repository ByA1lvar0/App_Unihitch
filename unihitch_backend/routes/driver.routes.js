const express = require('express');
const router = express.Router();
const driverController = require('../controllers/driver.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.use(authMiddleware);

router.post('/', driverController.uploadDocument);
router.get('/:id_conductor', driverController.getDocuments);
router.get('/:id_conductor/estado', driverController.getDocumentStatus);

// Admin routes
router.get('/admin/pending', driverController.getPendingDocuments);
router.put('/admin/:id/approve', driverController.approveDocument);
router.put('/admin/:id/reject', driverController.rejectDocument);

module.exports = router;
