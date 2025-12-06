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
        console.log('🚀 Iniciando migración de índices y restricciones...');

        const migrationPath = path.join(__dirname, 'migration_user_restrictions.sql');
        const sql = fs.readFileSync(migrationPath, 'utf8');

        await pool.query(sql);

        console.log('✅ Migración completada exitosamente');
        console.log('📊 Cambios aplicados:');
        console.log('   - Creados índices para tipo_usuario');
        console.log('   - Creados índices para es_agente_externo');
        console.log('   - Creados índices para viajes y reservas');
        console.log('   - Agregado constraint de validación para agentes externos');

        process.exit(0);
    } catch (error) {
        console.error('❌ Error en migración:', error.message);
        process.exit(1);
    }
}

runMigration();
