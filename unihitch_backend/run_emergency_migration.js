const pool = require('./config/db');
const fs = require('fs');
const path = require('path');

async function runMigration() {
    try {
        console.log('Iniciando migración de alertas de emergencia...');

        const sql = fs.readFileSync(path.join(__dirname, 'migration_emergency_alert.sql'), 'utf8');

        await pool.query(sql);

        console.log('✅ Tabla alerta_emergencia creada/verificada exitosamente');
    } catch (error) {
        console.error('❌ Error en la migración:', error);
    } finally {
        await pool.end();
    }
}

runMigration();
