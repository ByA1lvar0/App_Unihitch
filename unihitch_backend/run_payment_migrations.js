const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
});

async function runMigrations() {
    const client = await pool.connect();
    try {
        console.log('Ejecutando migraciones de sistema de pagos...');

        // Migración de cupones
        const couponsSql = fs.readFileSync(path.join(__dirname, 'migration_coupons.sql'), 'utf8');
        await client.query(couponsSql);
        console.log('✅ Migración de cupones completada');

        // Migración de referidos
        const referralsSql = fs.readFileSync(path.join(__dirname, 'migration_referrals.sql'), 'utf8');
        await client.query(referralsSql);
        console.log('✅ Migración de referidos completada');

        console.log('✅ Todas las migraciones completadas exitosamente!');
    } catch (error) {
        console.error('❌ Error en migración:', error);
    } finally {
        client.release();
        await pool.end();
    }
}

runMigrations();
