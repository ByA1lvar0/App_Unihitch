-- Tabla de cupones
CREATE TABLE IF NOT EXISTS cupon (
  id SERIAL PRIMARY KEY,
  codigo VARCHAR(50) UNIQUE NOT NULL,
  tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('PORCENTAJE', 'MONTO_FIJO')),
  valor NUMERIC(10, 2) NOT NULL,
  descripcion TEXT,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  fecha_expiracion TIMESTAMP,
  usos_maximos INTEGER DEFAULT NULL,
  usos_actuales INTEGER DEFAULT 0,
  activo BOOLEAN DEFAULT TRUE,
  id_creador INTEGER REFERENCES usuario(id)
);

-- Tabla de uso de cupones
CREATE TABLE IF NOT EXISTS cupon_uso (
  id SERIAL PRIMARY KEY,
  id_cupon INTEGER REFERENCES cupon(id) ON DELETE CASCADE,
  id_usuario INTEGER REFERENCES usuario(id) ON DELETE CASCADE,
  id_viaje INTEGER REFERENCES viaje(id),
  monto_descuento NUMERIC(10, 2),
  fecha_uso TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(id_cupon, id_usuario, id_viaje)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_cupon_codigo ON cupon(codigo);
CREATE INDEX IF NOT EXISTS idx_cupon_uso_usuario ON cupon_uso(id_usuario);
