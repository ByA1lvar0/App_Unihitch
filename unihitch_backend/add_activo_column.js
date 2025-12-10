const pool = require('./config/db');
require('dotenv').config();

async function checkAndAddActivoColumn() {
    try {
        // Check if 'activo' column exists
        const checkColumn = await pool.query(`
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name='usuario' AND column_name='activo'
        `);

        if (checkColumn.rows.length === 0) {
            console.log('Column "activo" does not exist. Creating it...');
            await pool.query(`
                ALTER TABLE usuario 
                ADD COLUMN activo BOOLEAN DEFAULT true
            `);
            console.log('✅ Column "activo" created successfully!');
        } else {
            console.log('✅ Column "activo" already exists.');
        }

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkAndAddActivoColumn();
