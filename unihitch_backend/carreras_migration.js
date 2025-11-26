const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function addCarrerasSystem() {
    const client = await pool.connect();

    try {
        console.log('🔄 Iniciando migración de sistema de carreras...');

        await client.query('BEGIN');

        // Crear tabla de carreras
        await client.query(`
      CREATE TABLE IF NOT EXISTS carrera (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(255) NOT NULL,
        id_universidad INTEGER REFERENCES universidad(id),
        activo BOOLEAN DEFAULT true,
        fecha_creacion TIMESTAMP DEFAULT NOW(),
        UNIQUE(nombre, id_universidad)
      )
    `);
        console.log('✅ Tabla carrera creada');

        // Agregar índice
        await client.query(`
      CREATE INDEX IF NOT EXISTS idx_carrera_universidad 
      ON carrera(id_universidad)
    `);

        // Insertar carreras por universidad
        const carreras = [
            // UTP (id: 1)
            { nombre: 'Ingeniería de Sistemas e Informática', id_universidad: 1 },
            { nombre: 'Ingeniería Industrial', id_universidad: 1 },
            { nombre: 'Ingeniería Civil', id_universidad: 1 },
            { nombre: 'Administración de Empresas', id_universidad: 1 },
            { nombre: 'Contabilidad', id_universidad: 1 },

            // Universidad Nacional de Piura (id: 2)
            { nombre: 'Ingeniería de Software', id_universidad: 2 },
            { nombre: 'Ingeniería Mecánica', id_universidad: 2 },
            { nombre: 'Ingeniería Civil', id_universidad: 2 },
            { nombre: 'Derecho', id_universidad: 2 },
            { nombre: 'Medicina', id_universidad: 2 },

            // UCV (id: 3)
            { nombre: 'Ingeniería de Sistemas', id_universidad: 3 },
            { nombre: 'Arquitectura', id_universidad: 3 },
            { nombre: 'Psicología', id_universidad: 3 },
            { nombre: 'Administración', id_universidad: 3 },
            { nombre: 'Derecho', id_universidad: 3 },
        ];

        for (const carrera of carreras) {
            await client.query(
                `INSERT INTO carrera (nombre, id_universidad) 
         VALUES ($1, $2) 
         ON CONFLICT (nombre, id_universidad) DO NOTHING`,
                [carrera.nombre, carrera.id_universidad]
            );
        }
        console.log('✅ Carreras insertadas');

        // Agregar columna id_carrera a tabla usuario si no existe
        await client.query(`
      ALTER TABLE usuario 
      ADD COLUMN IF NOT EXISTS id_carrera INTEGER REFERENCES carrera(id)
    `);
        console.log('✅ Columna id_carrera agregada a usuario');

        await client.query('COMMIT');
        console.log('✅ Migración completada exitosamente');

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('❌ Error en migración:', error);
        throw error;
    } finally {
        client.release();
        await pool.end();
    }
}

addCarrerasSystem()
    .then(() => {
        console.log('🎉 Sistema de carreras configurado');
        process.exit(0);
    })
    .catch((error) => {
        console.error('💥 Error:', error);
        process.exit(1);
    });
