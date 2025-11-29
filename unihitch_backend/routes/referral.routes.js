const express = require('express');
const router = express.Router();
const referralController = require('../controllers/referral.controller');

router.get('/code/:userId', referralController.getReferralCode);
router.post('/apply', referralController.applyReferralCode);
router.get('/stats/:userId', referralController.getReferralStats);

module.exports = router;
