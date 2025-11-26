-- Migración: Sistema de Recarga de Billetera
-- Fase 1: Yape Manual

-- Tabla para solicitudes de recarga
CREATE TABLE IF NOT EXISTS solicitudes_recarga (
  id SERIAL PRIMARY KEY,
  id_usuario INTEGER NOT NULL REFERENCES usuario(id),
  monto DECIMAL(10,2) NOT NULL,
  metodo VARCHAR(20) NOT NULL CHECK (metodo IN ('YAPE', 'CULQI')),
  estado VARCHAR(20) DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE', 'APROBADO', 'RECHAZADO')),
  
  -- Para Yape: comprobante en base64
  comprobante_base64 TEXT,
  numero_operacion VARCHAR(100),
  
  -- Para Culqi: referencia de transacción
  referencia_pago VARCHAR(100),
  
  -- Metadata
  fecha_solicitud TIMESTAMP DEFAULT NOW(),
  fecha_revision TIMESTAMP,
  id_revisor INTEGER REFERENCES usuario(id),
  motivo_rechazo TEXT,
  datos_extra JSONB,
  
  -- Validaciones
  CONSTRAINT monto_positivo CHECK (monto > 0),
  CONSTRAINT monto_minimo CHECK (monto >= 5.00),
  CONSTRAINT monto_maximo CHECK (monto <= 500.00)
);

-- Índices para optimizar consultas
CREATE INDEX idx_solicitudes_estado ON solicitudes_recarga(estado);
CREATE INDEX idx_solicitudes_usuario ON solicitudes_recarga(id_usuario);
CREATE INDEX idx_solicitudes_fecha ON solicitudes_recarga(fecha_solicitud DESC);
CREATE INDEX idx_solicitudes_metodo ON solicitudes_recarga(metodo);

-- Agregar campo a tabla transaccion para vincular recargas
ALTER TABLE transaccion 
ADD COLUMN IF NOT EXISTS id_solicitud_recarga INTEGER REFERENCES solicitudes_recarga(id);

-- Comentarios
COMMENT ON TABLE solicitudes_recarga IS 'Solicitudes de recarga de billetera (Yape manual y Culqi)';
COMMENT ON COLUMN solicitudes_recarga.metodo IS 'Método de pago: YAPE (manual) o CULQI (automático)';
COMMENT ON COLUMN solicitudes_recarga.estado IS 'Estado: PENDIENTE, APROBADO, RECHAZADO';
COMMENT ON COLUMN solicitudes_recarga.comprobante_base64 IS 'Screenshot del comprobante Yape en base64';
COMMENT ON COLUMN solicitudes_recarga.referencia_pago IS 'ID de transacción de Culqi';
