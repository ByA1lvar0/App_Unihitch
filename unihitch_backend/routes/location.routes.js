const express = require('express');
const router = express.Router();
const locationController = require('../controllers/location.controller');

router.post('/update', locationController.updateLocation);
router.get('/trip/:tripId', locationController.getTripParticipantsLocations);

module.exports = router;
