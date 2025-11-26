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
        const sql = fs.readFileSync('migration_admin_community.sql', 'utf8');
        await pool.query(sql);
        console.log('Migración completada con éxito');
    } catch (error) {
        console.error('Error en la migración:', error);
    } finally {
        await pool.end();
    }
}

runMigration();
