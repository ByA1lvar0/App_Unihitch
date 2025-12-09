const pool = require('./config/db');

async function createRutasTable() {
    const client = await pool.connect();

    try {
        console.log('Creando tabla rutas...');

        await client.query(`
            CREATE TABLE IF NOT EXISTS rutas (
                id SERIAL PRIMARY KEY,
                id_viaje INTEGER NOT NULL REFERENCES viaje(id) ON DELETE CASCADE,
                coordenadas JSONB NOT NULL,
                distancia_km DECIMAL(10, 2),
                duracion_minutos INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(id_viaje)
            );
        `);

        console.log('✓ Tabla rutas creada exitosamente');

        // Crear índices para mejor rendimiento
        await client.query(`
            CREATE INDEX IF NOT EXISTS idx_rutas_viaje ON rutas(id_viaje);
        `);

        console.log('✓ Índices creados');

    } catch (error) {
        console.error('Error creando tabla rutas:', error);
        throw error;
    } finally {
        client.release();
    }
}

// Ejecutar migración
createRutasTable()
    .then(() => {
        console.log('Migración completada');
        process.exit(0);
    })
    .catch((error) => {
        console.error('Error en migración:', error);
        process.exit(1);
    });
