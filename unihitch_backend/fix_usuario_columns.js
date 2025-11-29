const { Pool } = require('pg');
const fs = require('fs');
require('dotenv').config();

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function checkAndFix() {
    const client = await pool.connect();

    try {
        // Verificar columnas existentes
        const columnsResult = await client.query(`
      SELECT column_name
      FROM information_schema.columns
      WHERE table_name = 'usuario'
    `);

        const existingColumns = columnsResult.rows.map(r => r.column_name);
        console.log('Columnas existentes:', existingColumns.join(', '));

        let output = '=== MIGRACIÓN TIPO_USUARIO ===\n\n';
        output += 'Columnas existentes: ' + existingColumns.join(', ') + '\n\n';

        // Agregar es_agente_externo si no existe
        if (!existingColumns.includes('es_agente_externo')) {
            console.log('➕ Agregando columna es_agente_externo...');
            await client.query(`
        ALTER TABLE usuario 
        ADD COLUMN es_agente_externo BOOLEAN DEFAULT false
      `);
            output += '✅ Columna es_agente_externo agregada\n';
        } else {
            output += '✓ Columna es_agente_externo ya existe\n';
        }

        // Agregar tipo_usuario si no existe
        if (!existingColumns.includes('tipo_usuario')) {
            console.log('➕ Agregando columna tipo_usuario...');
            await client.query(`
        ALTER TABLE usuario 
        ADD COLUMN tipo_usuario VARCHAR(20) DEFAULT 'UNIVERSITARIO'
      `);
            output += '✅ Columna tipo_usuario agregada\n';

            // Actualizar valores basándose en es_agente_externo
            await client.query(`
        UPDATE usuario 
        SET tipo_usuario = CASE 
            WHEN es_agente_externo = true THEN 'AGENTE_EXTERNO'
            ELSE 'UNIVERSITARIO'
        END
      `);
            output += '✅ Valores actualizados\n';
        } else {
            output += '✓ Columna tipo_usuario ya existe\n';
        }

        // Verificar resultado
        const finalResult = await client.query(`
      SELECT column_name, data_type
      FROM information_schema.columns
      WHERE table_name = 'usuario'
      ORDER BY ordinal_position
    `);

        output += '\n=== COLUMNAS FINALES ===\n';
        finalResult.rows.forEach(row => {
            output += `${row.column_name}: ${row.data_type}\n`;
        });

        fs.writeFileSync('migration_result.txt', output);
        console.log('\n✅ Migración completada. Ver migration_result.txt');
        console.log(output);

    } catch (error) {
        console.error('❌ Error:', error.message);
        fs.writeFileSync('migration_result.txt', 'ERROR: ' + error.message);
    } finally {
        client.release();
        await pool.end();
    }
}

checkAndFix();
