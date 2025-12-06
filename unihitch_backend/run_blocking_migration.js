const fs = require('fs');
const pool = require('./config/db');

async function runMigration() {
    try {
        console.log('🚀 Iniciando migración de bloqueo y última conexión...');

        const sql = fs.readFileSync('./migration_blocking_lastseen.sql', 'utf8');

        await pool.query(sql);

        console.log('✅ Migración completada exitosamente');
        console.log('📋 Se creó:');
        console.log('   - Tabla usuario_bloqueado');
        console.log('   - Columna ultima_conexion en usuario');
        console.log('   - Índices correspondientes');

        process.exit(0);
    } catch (error) {
        console.error('❌ Error ejecutando migración:', error);
        process.exit(1);
    }
}

runMigration();
