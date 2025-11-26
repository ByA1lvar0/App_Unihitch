const express = require('express');
const router = express.Router();
const couponController = require('../controllers/coupon.controller');

router.post('/validate', couponController.validateCoupon);
router.post('/apply', couponController.applyCoupon);
router.post('/create', couponController.createCoupon);
router.get('/active', couponController.getActiveCoupons);

module.exports = router;
