const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
});

async function createBlockingTable() {
    try {
        console.log('Creando tabla usuario_bloqueado si no existe...');

        await pool.query(`
            CREATE TABLE IF NOT EXISTS usuario_bloqueado (
                id SERIAL PRIMARY KEY,
                id_usuario INTEGER REFERENCES usuario(id) NOT NULL,
                id_usuario_bloqueado INTEGER REFERENCES usuario(id) NOT NULL,
                fecha_bloqueo TIMESTAMP DEFAULT NOW(),
                UNIQUE(id_usuario, id_usuario_bloqueado)
            );
        `);

        console.log('✅ Tabla usuario_bloqueado creada/verificada exitosamente');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

createBlockingTable();
