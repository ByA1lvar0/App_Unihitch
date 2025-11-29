const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function runMigration() {
    try {
        const sql = fs.readFileSync(path.join(__dirname, 'migration_university_domains.sql'), 'utf8');
        await pool.query(sql);
        console.log('Migración de dominios ejecutada exitosamente.');
    } catch (error) {
        console.error('Error al ejecutar migración:', error);
    } finally {
        await pool.end();
    }
}

runMigration();
