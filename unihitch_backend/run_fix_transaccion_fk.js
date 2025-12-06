const { Client } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const client = new Client({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function runMigration() {
    try {
        await client.connect();
        console.log('🔌 Conectado a la base de datos');

        const sql = fs.readFileSync(path.join(__dirname, 'migration_fix_transaccion_fk.sql'), 'utf8');

        console.log('🚀 Ejecutando migración de corrección FK...');
        await client.query(sql);

        console.log('✅ Migración completada exitosamente');
    } catch (err) {
        console.error('❌ Error durante la migración:', err);
    } finally {
        await client.end();
    }
}

runMigration();
