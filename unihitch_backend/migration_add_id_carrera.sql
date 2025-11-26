-- Agregar columna id_carrera a la tabla usuario para referenciar carreras
ALTER TABLE usuario 
ADD COLUMN IF NOT EXISTS id_carrera INTEGER REFERENCES carrera(id);

-- Los datos existentes en 'carrera' (VARCHAR) se mantienen para compatibilidad
-- Nuevos registros usarán id_carrera
