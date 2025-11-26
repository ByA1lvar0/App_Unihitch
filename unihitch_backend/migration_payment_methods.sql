-- =====================================================
-- MIGRACIÓN: Sistema de Recargas con Yape/Plin
-- =====================================================

-- Tabla para almacenar comprobantes de recarga
CREATE TABLE IF NOT EXISTS comprobante_recarga (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuario(id) NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    metodo VARCHAR(20) NOT NULL, -- 'YAPE' o 'PLIN'
    numero_operacion VARCHAR(50), -- Número de operación del comprobante
    imagen_comprobante TEXT NOT NULL, -- URL o base64 de la imagen
    estado VARCHAR(20) DEFAULT 'COMPLETADA', -- Siempre COMPLETADA (automático)
    fecha_solicitud TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT
);

-- Tabla para configuración de cuentas de recepción
CREATE TABLE IF NOT EXISTS cuenta_recepcion (
    id SERIAL PRIMARY KEY,
    tipo VARCHAR(20) NOT NULL, -- 'YAPE' o 'PLIN'
    numero_celular VARCHAR(20) NOT NULL,
    nombre_titular VARCHAR(100) NOT NULL,
    qr_code TEXT, -- Imagen QR en base64 (opcional)
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar cuenta de Yape de la empresa
INSERT INTO cuenta_recepcion (tipo, numero_celular, nombre_titular, activo) 
VALUES ('YAPE', '928318308', 'UniHitch', true)
ON CONFLICT DO NOTHING;

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_comprobante_usuario ON comprobante_recarga(id_usuario);
CREATE INDEX IF NOT EXISTS idx_comprobante_fecha ON comprobante_recarga(fecha_solicitud);

COMMENT ON TABLE comprobante_recarga IS 'Comprobantes de recarga con Yape/Plin';
COMMENT ON TABLE cuenta_recepcion IS 'Cuentas de Yape/Plin para recibir pagos';
