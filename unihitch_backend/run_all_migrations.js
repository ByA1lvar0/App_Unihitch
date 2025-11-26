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

async function runMigrations() {
    const migrations = [
        'driver_documents_migration.sql',
        'cash_payments_migration.sql',
        'email_verification_migration.sql'
    ];

    console.log('🚀 Ejecutando migraciones...\n');

    for (const file of migrations) {
        try {
            console.log(`📄 Ejecutando: ${file}`);
            const sql = fs.readFileSync(`./${file}`, 'utf8');
            await pool.query(sql);
            console.log(`✅ ${file} - COMPLETADO\n`);
        } catch (error) {
            console.error(`❌ ${file} - ERROR:`, error.message, '\n');
        }
    }

    console.log('🎉 Migraciones finalizadas');
    process.exit(0);
}

runMigrations();
