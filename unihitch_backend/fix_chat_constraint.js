const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
});

async function fixChatConstraint() {
    try {
        console.log('Eliminando constraint check_chat_context...');

        // Eliminar el constraint que está causando problemas
        await pool.query(`
            ALTER TABLE chat DROP CONSTRAINT IF EXISTS check_chat_context;
        `);

        console.log('✅ Constraint eliminado exitosamente');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

fixChatConstraint();
