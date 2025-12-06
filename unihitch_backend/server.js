const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Servir archivos estáticos (panel web Leaflet)
app.use(express.static('public'));

// Import Routes
const authRoutes = require('./routes/auth.routes');
const universityRoutes = require('./routes/university.routes');
const tripRoutes = require('./routes/trip.routes');
const reservationRoutes = require('./routes/reservation.routes');
const walletRoutes = require('./routes/wallet.routes');
const chatRoutes = require('./routes/chat.routes');
const notificationRoutes = require('./routes/notification.routes');
const userRoutes = require('./routes/user.routes');
const adminRoutes = require('./routes/admin.routes');
const communityRoutes = require('./routes/community.routes');
const driverRoutes = require('./routes/driver.routes');
const locationRoutes = require('./routes/location.routes');
const ratingRoutes = require('./routes/rating.routes');
const historyRoutes = require('./routes/history.routes');
const favoritesRoutes = require('./routes/favorites.routes');
const couponRoutes = require('./routes/coupon.routes');
const referralRoutes = require('./routes/referral.routes');
const blockingRoutes = require('./routes/blocking.routes');
const emergencyRoutes = require('./routes/emergency.routes');
const carpoolingRoutes = require('./routes/carpooling.routes');
const routesRoutes = require('./routes/routes.routes');

// Mount Routes
app.use('/api', authRoutes); // /api/register, /api/login
app.use('/api', universityRoutes); // /api/universidades, /api/carreras/:id
app.use('/api/viajes', tripRoutes); // /api/viajes...
app.use('/api/reservas', reservationRoutes); // /api/reservas...
app.use('/api', walletRoutes); // /api/wallet..., /api/payment-methods...
app.use('/api', chatRoutes); // /api/chats..., /api/messages...
app.use('/api/notifications', notificationRoutes); // /api/notifications...
app.use('/api/users', userRoutes); // /api/users...
app.use('/api/usuarios', userRoutes); // Alias for /api/usuarios endpoint (maps to / in userRoutes)
app.use('/api/admin', adminRoutes); // /api/admin...
app.use('/api/community', communityRoutes); // /api/community...
app.use('/api/documentos-conductor', driverRoutes); // /api/documentos-conductor...
app.use('/api/location', locationRoutes); // /api/location...
app.use('/api/ratings', ratingRoutes); // /api/ratings...
app.use('/api/history', historyRoutes); // /api/history...
app.use('/api/favorites', favoritesRoutes); // /api/favorites...
app.use('/api/coupons', couponRoutes); // /api/coupons...
app.use('/api/referrals', referralRoutes); // /api/referrals...
app.use('/api/blocking', blockingRoutes); // /api/blocking...
app.use('/api/emergency', emergencyRoutes); // /api/emergency...
app.use('/api/carpooling', carpoolingRoutes); // /api/carpooling...
app.use('/api/routes', routesRoutes); // /api/routes...

// Root Endpoint
app.get('/', (req, res) => {
  res.send('UniHitch Backend Running');
});

// Start Server
app.listen(port, () => {
  console.log(`✅ Servidor corriendo en http://localhost:${port}`);
  console.log('🚀 Backend modularizado y activo.');
});
