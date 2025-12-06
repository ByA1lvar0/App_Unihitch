-- =====================================================
-- MIGRACIÓN: Preferencia de Método SOS
-- =====================================================
-- Agregar configuración de método preferido para alertas SOS

-- Agregar campo de método preferido a usuario
ALTER TABLE usuario 
ADD COLUMN IF NOT EXISTS metodo_emergencia_preferido VARCHAR(20) DEFAULT 'WHATSAPP';

-- Agregar campo es_principal a contacto_emergencia
ALTER TABLE contacto_emergencia 
ADD COLUMN IF NOT EXISTS es_principal BOOLEAN DEFAULT FALSE;

-- Comentarios
COMMENT ON COLUMN usuario.metodo_emergencia_preferido IS 'Método preferido para enviar alertas SOS: WHATSAPP o SMS. Si falla, se usa el otro como respaldo';
COMMENT ON COLUMN contacto_emergencia.es_principal IS 'Indica si es el contacto principal para emergencias';

-- Verificar que existan las tablas
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'usuario') THEN
        RAISE NOTICE 'Tabla usuario no existe. Ejecuta database_setup.sql primero.';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'contacto_emergencia') THEN
        RAISE NOTICE 'Tabla contacto_emergencia no existe. Ejecuta database_setup.sql primero.';
    END IF;
END $$;
