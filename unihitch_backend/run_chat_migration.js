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
        console.log('🚀 Iniciando migración de chat-viaje...');

        const migrationPath = path.join(__dirname, 'migration_chat_viaje_relation.sql');
        const sql = fs.readFileSync(migrationPath, 'utf8');

        await pool.query(sql);

        console.log('✅ Migración completada exitosamente');
        console.log('📊 Cambios aplicados:');
        console.log('   - Agregada columna id_viaje a tabla chat');
        console.log('   - Agregada columna id_reserva a tabla chat');
        console.log('   - Agregada columna tipo_chat a tabla chat');
        console.log('   - Creados índices para mejorar búsquedas');
        console.log('   - Agregado constraint de validación');

        process.exit(0);
    } catch (error) {
        console.error('❌ Error en migración:', error.message);
        process.exit(1);
    }
}

runMigration();
