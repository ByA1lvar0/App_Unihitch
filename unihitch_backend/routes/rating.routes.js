const express = require('express');
const router = express.Router();
const ratingController = require('../controllers/rating.controller');
const { ratingValidation } = require('../validators/rating.validator');

router.post('/', ratingValidation, ratingController.submitRating);
router.get('/:userId', ratingController.getRatings);

module.exports = router;
