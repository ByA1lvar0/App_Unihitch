-- Migración: Sistema de Documentos de Conductor
-- Fecha: 2025-11-24

-- Tabla para almacenar documentos del conductor (SOAT, Tarjeta Mantenimiento)
CREATE TABLE IF NOT EXISTS documentos_conductor (
    id SERIAL PRIMARY KEY,
    id_conductor INTEGER REFERENCES usuario(id) ON DELETE CASCADE,
    tipo_documento VARCHAR(50) NOT NULL, -- 'SOAT', 'TARJETA_MANTENIMIENTO', 'LICENCIA', 'DNI'
    archivo_base64 TEXT NOT NULL, -- Documento codificado en base64
    nombre_archivo VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100), -- image/jpeg, application/pdf, etc.
    tamanio_kb INTEGER, -- Tamaño en kilobytes
    estado VARCHAR(20) DEFAULT 'PENDIENTE', -- PENDIENTE, APROBADO, RECHAZADO
    fecha_vencimiento DATE,
    motivo_rechazo TEXT,
    notas_adicionales TEXT,
    fecha_subida TIMESTAMP DEFAULT NOW(),
    fecha_revision TIMESTAMP,
    id_revisor INTEGER REFERENCES usuario(id),
    UNIQUE(id_conductor, tipo_documento) -- Solo un documento de cada tipo por conductor
);

-- Agregar columnas al usuario para verificación de conductor
ALTER TABLE usuario 
ADD COLUMN IF NOT EXISTS puede_conducir BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS estado_verificacion_conductor VARCHAR(20) DEFAULT 'SIN_DOCUMENTOS',
ADD COLUMN IF NOT EXISTS fecha_verificacion_conductor TIMESTAMP;

-- Estados posibles: SIN_DOCUMENTOS, PENDIENTE_REVISION, VERIFICADO, RECHAZADO

-- Tabla para historial de cambios de estado
CREATE TABLE IF NOT EXISTS historial_verificacion_conductor (
    id SERIAL PRIMARY KEY,
    id_conductor INTEGER REFERENCES usuario(id) ON DELETE CASCADE,
    estado_anterior VARCHAR(20),
    estado_nuevo VARCHAR(20),
    comentario TEXT,
    id_admin INTEGER REFERENCES usuario(id),
    fecha_cambio TIMESTAMP DEFAULT NOW()
);

-- Índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_documentos_conductor ON documentos_conductor(id_conductor);
CREATE INDEX IF NOT EXISTS idx_documentos_estado ON documentos_conductor(estado);
CREATE INDEX IF NOT EXISTS idx_documentos_tipo ON documentos_conductor(tipo_documento);
CREATE INDEX IF NOT EXISTS idx_usuario_verificacion ON usuario(estado_verificacion_conductor);
CREATE INDEX IF NOT EXISTS idx_historial_conductor ON historial_verificacion_conductor(id_conductor);

-- Comentarios
COMMENT ON TABLE documentos_conductor IS 'Almacena documentos de verificación de conductores (SOAT, tarjeta mantenimiento)';
COMMENT ON COLUMN documentos_conductor.archivo_base64 IS 'Documento codificado en base64, máximo 5MB recomendado';
COMMENT ON COLUMN usuario.puede_conducir IS 'TRUE si el conductor fue verificado y puede ofrecer viajes';
