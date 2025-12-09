-- =====================================================
-- MIGRACIÓN: Relación entre Chat y Viaje
-- =====================================================
-- Esta migración agrega columnas para relacionar chats con viajes
-- y permite validar que agentes externos solo chateen sobre viajes activos

-- Agregar columnas para relacionar chat con viaje/reserva
ALTER TABLE chat ADD COLUMN IF NOT EXISTS id_viaje INTEGER REFERENCES viaje(id);
ALTER TABLE chat ADD COLUMN IF NOT EXISTS id_reserva INTEGER REFERENCES reserva(id);
ALTER TABLE chat ADD COLUMN IF NOT EXISTS tipo_chat VARCHAR(20);

-- Actualizar chats existentes como tipo COMUNIDAD (por defecto)
UPDATE chat SET tipo_chat = 'COMUNIDAD' WHERE tipo_chat IS NULL;

-- Ahora establecer el default para nuevos registros
ALTER TABLE chat ALTER COLUMN tipo_chat SET DEFAULT 'VIAJE';

-- Comentarios para documentar
COMMENT ON COLUMN chat.id_viaje IS 'ID del viaje asociado al chat (si aplica)';
COMMENT ON COLUMN chat.id_reserva IS 'ID de la reserva asociada al chat (si aplica)';
COMMENT ON COLUMN chat.tipo_chat IS 'Tipo de chat: VIAJE (conductor-pasajero) o COMUNIDAD (solo universitarios)';

-- Índices para mejorar búsquedas
CREATE INDEX IF NOT EXISTS idx_chat_viaje ON chat(id_viaje);
CREATE INDEX IF NOT EXISTS idx_chat_reserva ON chat(id_reserva);
CREATE INDEX IF NOT EXISTS idx_chat_tipo ON chat(tipo_chat);

-- Constraint: Si es chat de viaje, debe tener id_viaje o id_reserva
-- Solo aplicar a nuevos registros, los existentes ya son COMUNIDAD
ALTER TABLE chat ADD CONSTRAINT check_chat_context 
    CHECK (
        (tipo_chat = 'VIAJE' AND (id_viaje IS NOT NULL OR id_reserva IS NOT NULL)) OR
        (tipo_chat = 'COMUNIDAD')
    );

-- =====================================================
-- FIN DE MIGRACIÓN
-- =====================================================
