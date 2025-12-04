-- =====================================================
-- MIGRACIÓN: Índices para Mejorar Rendimiento
-- =====================================================
-- Esta migración agrega índices para mejorar el rendimiento
-- de búsquedas relacionadas con usuarios externos y viajes

-- Índices para búsquedas frecuentes de usuarios
CREATE INDEX IF NOT EXISTS idx_usuario_tipo ON usuario(tipo_usuario);
CREATE INDEX IF NOT EXISTS idx_usuario_universidad ON usuario(id_universidad) WHERE id_universidad IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_usuario_externo ON usuario(es_agente_externo) WHERE es_agente_externo = true;
CREATE INDEX IF NOT EXISTS idx_usuario_verificado ON usuario(verificado) WHERE verificado = false;

-- Índice para viajes por universidad (útil para filtrar viajes universitarios)
CREATE INDEX IF NOT EXISTS idx_viaje_universidad ON viaje(id_conductor);
CREATE INDEX IF NOT EXISTS idx_viaje_estado_fecha ON viaje(estado, fecha_hora) WHERE estado = 'DISPONIBLE';

-- Índices para reservas
CREATE INDEX IF NOT EXISTS idx_reserva_estado ON reserva(estado);
CREATE INDEX IF NOT EXISTS idx_reserva_viaje_pasajero ON reserva(id_viaje, id_pasajero);

-- Constraint para asegurar consistencia de agentes externos
-- Los agentes externos NO deben tener universidad asignada
ALTER TABLE usuario DROP CONSTRAINT IF EXISTS check_external_no_university;
ALTER TABLE usuario ADD CONSTRAINT check_external_no_university 
    CHECK (
        (es_agente_externo = true AND id_universidad IS NULL) OR
        (es_agente_externo = false) OR
        (es_agente_externo IS NULL)
    );

-- Comentarios para documentación
COMMENT ON INDEX idx_usuario_tipo IS 'Índice para filtrar usuarios por tipo (UNIVERSITARIO/AGENTE_EXTERNO)';
COMMENT ON INDEX idx_usuario_externo IS 'Índice parcial para agentes externos';
COMMENT ON INDEX idx_chat_viaje IS 'Índice para buscar chats relacionados con viajes';

-- =====================================================
-- FIN DE MIGRACIÓN
-- =====================================================
