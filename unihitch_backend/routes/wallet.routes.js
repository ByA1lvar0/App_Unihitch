const express = require('express');
const router = express.Router();
const walletController = require('../controllers/wallet.controller');

// Wallet Routes - Specific routes FIRST
router.post('/wallet/recarga-manual', walletController.rechargeManual);
router.get('/wallet/recarga-pendientes', walletController.getPendingRecharges);
router.post('/wallet/recarga-culqi', walletController.rechargeCulqi);
router.post('/wallet/recharge-request', walletController.rechargeRequest);
router.post('/wallet/recharge-card', walletController.rechargeCard);
router.post('/wallet/withdrawal-request', walletController.requestWithdrawal);
router.get('/wallet/withdrawals-pending', walletController.getPendingWithdrawals);
router.put('/wallet/withdrawal/:id/process', walletController.processWithdrawal);

// Payment Accounts Routes
router.get('/payment-accounts', walletController.getPaymentAccounts);

// Admin Routes (related to wallet)
router.post('/admin/aprobar-recarga/:id', walletController.approveRecharge);
router.post('/admin/rechazar-recarga/:id', walletController.rejectRecharge);

// Payment Methods Routes
router.post('/payment-methods', walletController.addPaymentMethod);
router.delete('/payment-methods/:id', walletController.deletePaymentMethod);
router.put('/payment-methods/:id/set-primary', walletController.setPrimaryPaymentMethod);
router.get('/payment-methods/:userId', walletController.getPaymentMethods);

// Wallet Routes - Parameterized routes LAST
router.get('/wallet/mis-solicitudes/:userId', walletController.getMyRecharges);
router.get('/wallet/recharge-history/:userId', walletController.getRechargeHistory);
router.get('/wallet/withdrawals/:userId', walletController.getWithdrawals);
router.get('/wallet/co2-stats/:userId', walletController.getCO2Stats);
router.get('/wallet/:userId', walletController.getWallet);

module.exports = router;
