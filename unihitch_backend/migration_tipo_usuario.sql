-- Agregar columna tipo_usuario a la tabla usuario
-- Esta columna distingue entre UNIVERSITARIO y AGENTE_EXTERNO

ALTER TABLE usuario 
ADD COLUMN IF NOT EXISTS tipo_usuario VARCHAR(20) DEFAULT 'UNIVERSITARIO';

-- Actualizar los registros existentes basándose en es_agente_externo
UPDATE usuario 
SET tipo_usuario = CASE 
    WHEN es_agente_externo = true THEN 'AGENTE_EXTERNO'
    ELSE 'UNIVERSITARIO'
END
WHERE tipo_usuario IS NULL OR tipo_usuario = 'UNIVERSITARIO';

-- Agregar constraint para validar valores
ALTER TABLE usuario 
ADD CONSTRAINT check_tipo_usuario 
CHECK (tipo_usuario IN ('UNIVERSITARIO', 'AGENTE_EXTERNO'));

-- Mostrar resultado
SELECT id, nombre, correo, tipo_usuario, es_agente_externo 
FROM usuario 
LIMIT 10;
