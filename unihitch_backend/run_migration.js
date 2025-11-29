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
    console.log('Ejecutando migración...');
    
    // Crear tabla comprobante_recarga
    await client.query(`
      CREATE TABLE IF NOT EXISTS comprobante_recarga (
        id SERIAL PRIMARY KEY,
        id_usuario INTEGER REFERENCES usuario(id) NOT NULL,
        monto DECIMAL(10,2) NOT NULL,
        metodo VARCHAR(20) NOT NULL,
        numero_operacion VARCHAR(50),
        imagen_comprobante TEXT NOT NULL,
        estado VARCHAR(20) DEFAULT 'COMPLETADA',
        fecha_solicitud TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        observaciones TEXT
      )
    `);
    console.log('✓ Tabla comprobante_recarga creada');

    // Crear tabla cuenta_recepcion
    await client.query(`
      CREATE TABLE IF NOT EXISTS cuenta_recepcion (
        id SERIAL PRIMARY KEY,
        tipo VARCHAR(20) NOT NULL,
        numero_celular VARCHAR(20) NOT NULL,
        nombre_titular VARCHAR(100) NOT NULL,
        qr_code TEXT,
        activo BOOLEAN DEFAULT TRUE,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✓ Tabla cuenta_recepcion creada');

    // Insertar cuenta de Yape
    const result = await client.query(`
      INSERT INTO cuenta_recepcion (tipo, numero_celular, nombre_titular, activo) 
      VALUES ('YAPE', '928318308', 'UniHitch', true)
      ON CONFLICT DO NOTHING
      RETURNING *
    `);
    
    if (result.rows.length > 0) {
      console.log('✓ Cuenta Yape insertada:', result.rows[0]);
    } else {
      console.log('✓ Cuenta Yape ya existe');
    }

    // Crear índices
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_comprobante_usuario ON comprobante_recarga(id_usuario)
    `);
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_comprobante_fecha ON comprobante_recarga(fecha_solicitud)
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
