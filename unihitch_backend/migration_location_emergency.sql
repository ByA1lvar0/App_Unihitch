-- Add columns for emergency contacts and location tracking
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS contactos_emergencia TEXT;
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS latitud DECIMAL(10, 8);
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS longitud DECIMAL(11, 8);
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS ultima_actualizacion_ubicacion TIMESTAMP;
