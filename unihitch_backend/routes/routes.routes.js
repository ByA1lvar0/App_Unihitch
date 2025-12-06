const express = require('express');
const router = express.Router();
const routesController = require('../controllers/routes.controller');

// Obtener ruta de un viaje específico
router.get('/:tripId', routesController.getRouteByTrip);

// Crear o actualizar ruta para un viaje
router.post('/', routesController.createOrUpdateRoute);

// Obtener todas las rutas activas
router.get('/active/all', routesController.getActiveRoutes);

// Calcular preview de ruta (sin guardar)
router.post('/calculate/preview', routesController.calculateRoutePreview);

module.exports = router;
