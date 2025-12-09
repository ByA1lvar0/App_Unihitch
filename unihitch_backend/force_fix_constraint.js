const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
});

async function forceRemoveConstraint() {
    try {
        console.log('Intentando eliminar constraint check_chat_context...');

        await pool.query(`
            ALTER TABLE chat DROP CONSTRAINT IF EXISTS check_chat_context;
        `);

        console.log('✅ Constraint eliminado (si existía)');

        // Verificamos si existe algún otro constraint similar
        const res = await pool.query(`
            SELECT conname
            FROM pg_constraint
            WHERE conrelid = 'chat'::regclass;
        `);

        console.log('Constraints actuales en tabla chat:', res.rows.map(r => r.conname));

        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

forceRemoveConstraint();
