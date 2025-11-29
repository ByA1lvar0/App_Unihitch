const { Pool } = require('pg');
require('dotenv').config();

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
        console.log('🔄 Ejecutando migración: Agregar columna tipo_usuario...');

        // Agregar columna tipo_usuario
        await client.query(`
      ALTER TABLE usuario 
      ADD COLUMN IF NOT EXISTS tipo_usuario VARCHAR(20) DEFAULT 'UNIVERSITARIO'
    `);
        console.log('✅ Columna tipo_usuario agregada');

        // Actualizar registros existentes
        await client.query(`
      UPDATE usuario 
      SET tipo_usuario = CASE 
          WHEN es_agente_externo = true THEN 'AGENTE_EXTERNO'
          ELSE 'UNIVERSITARIO'
      END
      WHERE tipo_usuario IS NULL OR tipo_usuario = 'UNIVERSITARIO'
    `);
        console.log('✅ Registros existentes actualizados');

        // Agregar constraint
        await client.query(`
      DO $$ 
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint WHERE conname = 'check_tipo_usuario'
        ) THEN
          ALTER TABLE usuario 
          ADD CONSTRAINT check_tipo_usuario 
          CHECK (tipo_usuario IN ('UNIVERSITARIO', 'AGENTE_EXTERNO'));
        END IF;
      END $$;
    `);
        console.log('✅ Constraint agregado');

        // Mostrar resultado
        const result = await client.query(`
      SELECT id, nombre, correo, tipo_usuario, es_agente_externo 
      FROM usuario 
      LIMIT 10
    `);

        console.log('\n📊 Primeros 10 usuarios:');
        console.table(result.rows);

        console.log('\n✅ Migración completada exitosamente');

    } catch (error) {
        console.error('❌ Error en la migración:', error);
        throw error;
    } finally {
        client.release();
        await pool.end();
    }
}

runMigration()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
