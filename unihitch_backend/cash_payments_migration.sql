-- Migración: Sistema de Pagos en Efectivo
-- Fecha: 2025-11-24

-- Agregar columna de método de pago a reservas
ALTER TABLE reserva 
ADD COLUMN IF NOT EXISTS metodo_pago VARCHAR(20) DEFAULT 'WALLET',
ADD COLUMN IF NOT EXISTS pago_efectivo_confirmado BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS fecha_confirmacion_efectivo TIMESTAMP,
ADD COLUMN IF NOT EXISTS monto_efectivo DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS confirmado_por INTEGER REFERENCES usuario(id);

-- CHECK constraint para métodos de pago válidos
ALTER TABLE reserva 
ADD CONSTRAINT check_metodo_pago 
CHECK (metodo_pago IN ('WALLET', 'EFECTIVO'));

-- Tabla para registro de confirmaciones de pago en efectivo
CREATE TABLE IF NOT EXISTS confirmaciones_pago_efectivo (
    id SERIAL PRIMARY KEY,
    id_reserva INTEGER REFERENCES reserva(id) ON DELETE CASCADE,
    id_conductor INTEGER REFERENCES usuario(id),
    id_pasajero INTEGER REFERENCES usuario(id),
    monto DECIMAL(10,2) NOT NULL,
    fecha_confirmacion TIMESTAMP DEFAULT NOW(),
    ubicacion_lat DECIMAL(10, 8),
    ubicacion_lng DECIMAL(11, 8),
    comentarios TEXT
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_reserva_metodo_pago ON reserva(metodo_pago);
CREATE INDEX IF NOT EXISTS idx_reserva_efectivo_pendiente ON reserva(metodo_pago, pago_efectivo_confirmado) 
WHERE metodo_pago = 'EFECTIVO' AND pago_efectivo_confirmado = FALSE;
CREATE INDEX IF NOT EXISTS idx_confirmaciones_pago ON confirmaciones_pago_efectivo(id_reserva);

-- Comentarios
COMMENT ON COLUMN reserva.metodo_pago IS 'WALLET: pago por billetera digital, EFECTIVO: pago en efectivo al conductor';
COMMENT ON COLUMN reserva.pago_efectivo_confirmado IS 'TRUE cuando el conductor confirma que recibió el pago en efectivo';
COMMENT ON TABLE confirmaciones_pago_efectivo IS 'Registro de confirmaciones de pagos en efectivo para auditoría';
