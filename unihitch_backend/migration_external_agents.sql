-- Migración: Sistema de Agentes Externos
-- Fecha: 2025-11-24
-- Descripción: Agrega soporte para usuarios externos (sin afiliación universitaria)

-- Agregar columnas para identificar tipo de usuario
ALTER TABLE usuario 
ADD COLUMN IF NOT EXISTS tipo_usuario VARCHAR(20) DEFAULT 'UNIVERSITARIO',
ADD COLUMN IF NOT EXISTS es_agente_externo BOOLEAN DEFAULT FALSE;

-- Comentarios
COMMENT ON COLUMN usuario.tipo_usuario IS 'Tipo de usuario: UNIVERSITARIO o AGENTE_EXTERNO';
COMMENT ON COLUMN usuario.es_agente_externo IS 'TRUE si el usuario es un agente externo sin afiliación universitaria';

-- Actualizar usuarios existentes (todos son universitarios por defecto)
UPDATE usuario 
SET tipo_usuario = 'UNIVERSITARIO', 
    es_agente_externo = FALSE 
WHERE tipo_usuario IS NULL OR es_agente_externo IS NULL;

-- Hacer campos universitarios opcionales para agentes externos
-- Los agentes externos tendrán id_universidad y id_carrera en NULL
ALTER TABLE usuario 
ALTER COLUMN id_universidad DROP NOT NULL;

-- Índice para mejorar consultas por tipo de usuario
CREATE INDEX IF NOT EXISTS idx_usuario_tipo ON usuario(tipo_usuario);
CREATE INDEX IF NOT EXISTS idx_usuario_agente_externo ON usuario(es_agente_externo);

-- Constraint para validar valores de tipo_usuario
ALTER TABLE usuario 
ADD CONSTRAINT chk_tipo_usuario 
CHECK (tipo_usuario IN ('UNIVERSITARIO', 'AGENTE_EXTERNO'));
