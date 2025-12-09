const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
});

async function migrateChatTable() {
    try {
        console.log('Agregando columnas a la tabla chat...');

        await pool.query(`
            ALTER TABLE chat 
            ADD COLUMN IF NOT EXISTS id_viaje INTEGER REFERENCES viaje(id),
            ADD COLUMN IF NOT EXISTS id_reserva INTEGER REFERENCES reserva(id),
            ADD COLUMN IF NOT EXISTS tipo_chat VARCHAR(20) DEFAULT 'COMUNIDAD';
        `);

        console.log('✅ Migración completada exitosamente');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error en migración:', error);
        process.exit(1);
    }
}

migrateChatTable();
