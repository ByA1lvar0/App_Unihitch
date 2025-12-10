const express = require('express');
const router = express.Router();
const tripController = require('../controllers/trip.controller');
const { createTripValidation } = require('../validators/trip.validator');
const { blockExternalUsers } = require('../middleware/external-user.middleware');
const { verifyDriverDocuments } = require('../middleware/driver-validation.middleware');
const authMiddleware = require('../middleware/auth.middleware');

router.use(authMiddleware);

// Todos pueden buscar y ver viajes disponibles
router.get('/', tripController.getTrips);
router.get('/search', tripController.searchTrips);

// Todos pueden crear viajes PERO deben tener documentos aprobados (SOAT, Licencia)
router.post('/', createTripValidation, verifyDriverDocuments, tripController.createTrip);

// Todos pueden ver viajes de un conductor específico
router.get('/conductor/:id', tripController.getDriverTrips);

// Seguimiento en tiempo real
router.post('/:id/ubicacion', tripController.updateLocation);
router.get('/:id/ubicaciones', tripController.getTripLocations);

module.exports = router;

