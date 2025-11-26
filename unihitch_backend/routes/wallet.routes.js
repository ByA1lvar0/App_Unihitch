const express = require('express');
const router = express.Router();
const walletController = require('../controllers/wallet.controller');

router.get('/:userId', walletController.getWallet);
router.post('/recarga-manual', walletController.rechargeManual);
router.get('/recarga-pendientes', walletController.getPendingRecharges);
router.post('/admin/aprobar-recarga/:id', walletController.approveRecharge);
router.post('/admin/rechazar-recarga/:id', walletController.rejectRecharge);
router.get('/mis-solicitudes/:userId', walletController.getMyRecharges);
router.post('/recarga-culqi', walletController.rechargeCulqi);

// Payment Methods
router.get('/payment-methods/:userId', walletController.getPaymentMethods); // Note: In server.js it was /api/payment-methods/:userId, here it will be /api/wallet/payment-methods/:userId if mounted on /api/wallet
// Wait, the original routes were /api/payment-methods... not /api/wallet/payment-methods.
// I should probably group them under /api/wallet for consistency or keep them separate.
// To avoid breaking frontend, I should try to keep paths similar or update frontend.
// But refactoring usually implies cleaning up routes.
// Let's keep them in this file but I might need to mount this router multiple times or handle paths carefully.
// Actually, I'll define the paths relative to the mount point.
// If I mount this router at /api, then I can define /wallet/:userId, /payment-methods/:userId etc.
// But usually we mount at /api/wallet.
// Let's stick to the plan of refactoring. I will mount this at `/api` and define full paths here to match original server.js structure, OR better, I will group them logically.
// If I group them, I break frontend.
// Strategy: In `server.js`, I will use:
// app.use('/api/wallet', walletRoutes);
// app.use('/api/payment-methods', paymentMethodRoutes);
// But that splits the controller.
// I'll put everything in `wallet.routes.js` but I'll have to mount it at `/api` and include the prefix in the route here.
// OR I can split into `wallet.routes.js` and `payment.routes.js`.
// Let's split for better modularity.

// I will create `wallet.routes.js` for /api/wallet/... routes
// And `payment.routes.js` for /api/payment-methods... routes?
// No, let's keep it simple. I'll use `wallet.routes.js` and mount it at `/api`.

// Wallet Routes
router.get('/wallet/:userId', walletController.getWallet);
router.post('/wallet/recarga-manual', walletController.rechargeManual);
router.get('/wallet/recarga-pendientes', walletController.getPendingRecharges);
router.get('/wallet/mis-solicitudes/:userId', walletController.getMyRecharges);
router.post('/wallet/recarga-culqi', walletController.rechargeCulqi);
router.post('/wallet/recharge-request', walletController.rechargeRequest);
router.post('/wallet/recharge-card', walletController.rechargeCard);
router.get('/wallet/recharge-history/:userId', walletController.getRechargeHistory);
router.post('/wallet/withdrawal-request', walletController.requestWithdrawal);
router.get('/wallet/withdrawals/:userId', walletController.getWithdrawals);
router.put('/wallet/withdrawal/:id/process', walletController.processWithdrawal);
router.get('/wallet/co2-stats/:userId', walletController.getCO2Stats);

// Admin Routes (related to wallet)
router.post('/admin/aprobar-recarga/:id', walletController.approveRecharge);
router.post('/admin/rechazar-recarga/:id', walletController.rejectRecharge);

// Payment Methods Routes
router.get('/payment-methods/:userId', walletController.getPaymentMethods);
router.post('/payment-methods', walletController.addPaymentMethod);
router.delete('/payment-methods/:id', walletController.deletePaymentMethod);
router.put('/payment-methods/:id/set-primary', walletController.setPrimaryPaymentMethod);

// Payment Accounts Routes
router.get('/payment-accounts', walletController.getPaymentAccounts);

module.exports = router;
