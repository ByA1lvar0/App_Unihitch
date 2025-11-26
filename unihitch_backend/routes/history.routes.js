const express = require('express');
const router = express.Router();
const historyController = require('../controllers/history.controller');

router.get('/:userId', historyController.getTripHistory);
router.get('/statistics/:userId', historyController.getUserStatistics);

module.exports = router;
