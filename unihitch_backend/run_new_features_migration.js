require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function runMigration() {
    const client = await pool.connect();

    try {
        console.log('🚀 Starting new features migration...\n');

        const migrationSQL = fs.readFileSync(
            path.join(__dirname, 'migration_new_features.sql'),
            'utf8'
        );

        await client.query(migrationSQL);

        console.log('\n✅ Migration completed successfully!');
        console.log('📊 New features ready:');
        console.log('   - Emergency Contacts System');
        console.log('   - Enhanced Notifications');
        console.log('   - Carpooling/Group Trips');

    } catch (error) {
        console.error('❌ Migration failed:', error.message);
        console.error(error);
        process.exit(1);
    } finally {
        client.release();
        await pool.end();
    }
}

runMigration();
