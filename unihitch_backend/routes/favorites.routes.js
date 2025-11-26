const express = require('express');
const router = express.Router();
const favoritesController = require('../controllers/favorites.controller');

// Conductores favoritos
router.post('/drivers', favoritesController.addFavoriteDriver);
router.delete('/drivers/:userId/:driverId', favoritesController.removeFavoriteDriver);
router.get('/drivers/:userId', favoritesController.getFavoriteDrivers);

// Rutas favoritas
router.post('/routes', favoritesController.addFavoriteRoute);
router.delete('/routes/:routeId', favoritesController.removeFavoriteRoute);
router.get('/routes/:userId', favoritesController.getFavoriteRoutes);

module.exports = router;
