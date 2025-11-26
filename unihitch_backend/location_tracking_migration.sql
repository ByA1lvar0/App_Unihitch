-- Agregar columnas de ubicación y número de emergencia a usuario
ALTER TABLE usuario 
ADD COLUMN IF NOT EXISTS ubicacion_lat DECIMAL(10, 8),
ADD COLUMN IF NOT EXISTS ubicacion_lng DECIMAL(11, 8),
ADD COLUMN IF NOT EXISTS ubicacion_actualizada TIMESTAMP,
ADD COLUMN IF NOT EXISTS numero_emergencia VARCHAR(20);

-- Crear tabla para tracking de ubicaciones en viajes activos
CREATE TABLE IF NOT EXISTS ubicacion_viaje (
    id SERIAL PRIMARY KEY,
    id_viaje INTEGER REFERENCES viaje(id) ON DELETE CASCADE,
    id_usuario INTEGER REFERENCES usuario(id) ON DELETE CASCADE,
    latitud DECIMAL(10, 8) NOT NULL,
    longitud DECIMAL(11, 8) NOT NULL,
    fecha_actualizacion TIMESTAMP DEFAULT NOW(),
    UNIQUE(id_viaje, id_usuario)
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_ubicacion_viaje_viaje ON ubicacion_viaje(id_viaje);
CREATE INDEX IF NOT EXISTS idx_ubicacion_viaje_usuario ON ubicacion_viaje(id_usuario);
CREATE INDEX IF NOT EXISTS idx_usuario_ubicacion ON usuario(ubicacion_lat, ubicacion_lng);

-- Comentarios
COMMENT ON TABLE ubicacion_viaje IS 'Almacena ubicaciones en tiempo real de conductor y pasajeros durante un viaje activo';
COMMENT ON COLUMN usuario.numero_emergencia IS 'Número de emergencia personal del usuario';
