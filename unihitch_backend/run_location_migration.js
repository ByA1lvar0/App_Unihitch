const { Pool } = require('pg');
const fs = require('fs');
require('dotenv').config();

const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
});

async function runMigration() {
    try {
        console.log('Ejecutando migración de ubicaciones...');

        const sql = fs.readFileSync('./location_tracking_migration.sql', 'utf8');

        await pool.query(sql);

        console.log('✓ Migración completada exitosamente');
        console.log('- Columnas de ubicación agregadas a usuario');
        console.log('- Tabla ubicacion_viaje creada');
        console.log('- Índices creados');

        process.exit(0);
    } catch (error) {
        console.error('Error ejecutando migración:', error);
        process.exit(1);
    }
}

runMigration();
