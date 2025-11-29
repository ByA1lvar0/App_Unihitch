const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
});

async function runMigration() {
    const client = await pool.connect();
    try {
        console.log('Ejecutando migración del sistema de billetera...');

        // Crear tabla de métodos de pago
        await client.query(`
      CREATE TABLE IF NOT EXISTS payment_method (
        id SERIAL PRIMARY KEY,
        id_usuario INTEGER REFERENCES usuario(id) NOT NULL,
        tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('YAPE', 'PLIN', 'TARJETA')),
        numero VARCHAR(100) NOT NULL,
        nombre_titular VARCHAR(100),
        es_principal BOOLEAN DEFAULT FALSE,
        activo BOOLEAN DEFAULT TRUE,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        fecha_expiracion VARCHAR(7), -- MM/YYYY para tarjetas
        cvv_encrypted VARCHAR(255) -- Encriptado para tarjetas
      )
    `);
        console.log('✓ Tabla payment_method creada');

        // Crear tabla de solicitudes de retiro
        await client.query(`
      CREATE TABLE IF NOT EXISTS withdrawal_request (
        id SERIAL PRIMARY KEY,
        id_usuario INTEGER REFERENCES usuario(id) NOT NULL,
        monto DECIMAL(10,2) NOT NULL CHECK (monto > 0),
        metodo VARCHAR(20) NOT NULL CHECK (metodo IN ('YAPE', 'PLIN')),
        numero_destino VARCHAR(20) NOT NULL,
        estado VARCHAR(20) DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE', 'PROCESADO', 'RECHAZADO')),
        fecha_solicitud TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        fecha_procesado TIMESTAMP,
        observaciones TEXT,
        procesado_por INTEGER REFERENCES usuario(id)
      )
    `);
        console.log('✓ Tabla withdrawal_request creada');

        // Agregar columna tipo_recarga a comprobante_recarga si no existe
        await client.query(`
      DO $$ 
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name='comprobante_recarga' AND column_name='tipo_recarga'
        ) THEN
          ALTER TABLE comprobante_recarga 
          ADD COLUMN tipo_recarga VARCHAR(20) DEFAULT 'TRANSFERENCIA' 
          CHECK (tipo_recarga IN ('TRANSFERENCIA', 'TARJETA'));
        END IF;
      END $$;
    `);
        console.log('✓ Columna tipo_recarga agregada a comprobante_recarga');

        // Crear índices
        await client.query(`
      CREATE INDEX IF NOT EXISTS idx_payment_method_usuario ON payment_method(id_usuario);
    `);
        await client.query(`
      CREATE INDEX IF NOT EXISTS idx_payment_method_activo ON payment_method(activo);
    `);
        await client.query(`
      CREATE INDEX IF NOT EXISTS idx_withdrawal_usuario ON withdrawal_request(id_usuario);
    `);
        await client.query(`
      CREATE INDEX IF NOT EXISTS idx_withdrawal_estado ON withdrawal_request(estado);
    `);
        console.log('✓ Índices creados');

        console.log('\n✅ Migración completada exitosamente!');
    } catch (error) {
        console.error('❌ Error en migración:', error);
    } finally {
        client.release();
        await pool.end();
    }
}

runMigration();
