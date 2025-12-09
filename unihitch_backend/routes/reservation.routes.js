const express = require('express');
const router = express.Router();
const reservationController = require('../controllers/reservation.controller');
const { blockExternalUsers } = require('../middleware/external-user.middleware');

// Solo universitarios pueden reservar viajes
router.post('/', blockExternalUsers, reservationController.createReservation);

// Todos pueden ver sus propias reservas
router.get('/pasajero/:id', reservationController.getMyReservations);

// Todos pueden cancelar sus reservas
router.put('/:id/cancelar', reservationController.cancelReservation);

module.exports = router;

