const express = require('express');
const router = express.Router();
const reservationController = require('../controllers/reservation.controller');

router.post('/', reservationController.createReservation);
router.get('/pasajero/:id', reservationController.getMyReservations);
router.put('/:id/cancelar', reservationController.cancelReservation);

module.exports = router;
