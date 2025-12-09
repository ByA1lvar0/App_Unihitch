-- Agregar columnas faltantes a la tabla chat
ALTER TABLE chat 
ADD COLUMN IF NOT EXISTS id_viaje INTEGER REFERENCES viaje(id),
ADD COLUMN IF NOT EXISTS id_reserva INTEGER REFERENCES reserva(id),
ADD COLUMN IF NOT EXISTS tipo_chat VARCHAR(20) DEFAULT 'COMUNIDAD';
