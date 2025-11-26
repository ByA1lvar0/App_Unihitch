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
        console.log('Iniciando migración de múltiples dominios...');

        const sqlPath = path.join(__dirname, 'migration_multi_domains.sql');
        const sql = fs.readFileSync(sqlPath, 'utf8');

        await client.query('BEGIN');
        await client.query(sql);
        await client.query('COMMIT');

        console.log('¡Migración completada exitosamente!');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error durante la migración:', error);
    } finally {
        client.release();
        pool.end();
    }
}

runMigration();
