const express = require('express');
const router = express.Router();
const tripController = require('../controllers/trip.controller');
const { createTripValidation } = require('../validators/trip.validator');

router.get('/', tripController.getTrips);
router.post('/', createTripValidation, tripController.createTrip);
router.get('/search', tripController.searchTrips);
router.get('/conductor/:id', tripController.getDriverTrips);

module.exports = router;
