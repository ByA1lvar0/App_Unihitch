const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function checkTable() {
    const client = await pool.connect();

    try {
        console.log('🔍 Verificando estructura de la tabla usuario...\n');

        const result = await client.query(`
      SELECT column_name, data_type, character_maximum_length, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'usuario'
      ORDER BY ordinal_position
    `);

        console.log('📊 Columnas de la tabla usuario:');
        console.table(result.rows);

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        client.release();
        await pool.end();
    }
}

checkTable();
