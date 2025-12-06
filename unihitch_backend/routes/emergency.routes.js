const express = require('express');
const router = express.Router();
const emergencyController = require('../controllers/emergency.controller');

// Emergency Contacts
router.get('/contacts/:userId', emergencyController.getEmergencyContacts);
router.post('/contacts', emergencyController.addEmergencyContact);
router.put('/contacts/:id', emergencyController.updateEmergencyContact);
router.delete('/contacts/:id', emergencyController.deleteEmergencyContact);

// Emergency Configuration
router.get('/config/:userId', emergencyController.getEmergencyConfig);
router.put('/config/:userId', emergencyController.updateEmergencyConfig);

// Emergency Alert
router.post('/alert', emergencyController.sendEmergencyAlert);

// Emergency Method Preference
router.get('/preference/:userId', emergencyController.getEmergencyPreference);
router.put('/preference/:userId', emergencyController.updateEmergencyPreference);

module.exports = router;
