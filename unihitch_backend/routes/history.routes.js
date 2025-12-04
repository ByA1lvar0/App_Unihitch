const express = require('express');
const router = express.Router();
const historyController = require('../controllers/history.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.get('/:userId', authMiddleware, historyController.getTripHistory);
router.get('/statistics/:userId', authMiddleware, historyController.getUserStatistics);

module.exports = router;
