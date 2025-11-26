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

async function runMigration() {
    const client = await pool.connect();
    try {
        console.log('Ejecutando migración de favoritos...');

        const sqlPath = path.join(__dirname, 'migration_favorites.sql');
        const sql = fs.readFileSync(sqlPath, 'utf8');

        await client.query(sql);

        console.log('✅ Migración de favoritos completada exitosamente!');
    } catch (error) {
        console.error('❌ Error en migración:', error);
    } finally {
        client.release();
        await pool.end();
    }
}

runMigration();
