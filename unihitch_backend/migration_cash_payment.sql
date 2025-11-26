-- Migración: Soporte para pago en efectivo
-- Fecha: 2025-11-24

-- Agregar campo para aceptar efectivo en viajes
ALTER TABLE viajes 
ADD COLUMN IF NOT EXISTS acepta_efectivo BOOLEAN DEFAULT false;

-- Agregar campo para método de pago en reservas
ALTER TABLE reservas 
ADD COLUMN IF NOT EXISTS metodo_pago VARCHAR(20) DEFAULT 'WALLET';

-- Agregar constraint para validar método de pago (si no existe)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_metodo_pago') THEN
        ALTER TABLE reservas 
        ADD CONSTRAINT check_metodo_pago 
        CHECK (metodo_pago IN ('WALLET', 'EFECTIVO'));
    END IF;
END $$;

-- Comentarios
COMMENT ON COLUMN viajes.acepta_efectivo IS 'Indica si el conductor acepta pagos en efectivo';
COMMENT ON COLUMN reservas.metodo_pago IS 'Método de pago: WALLET (billetera) o EFECTIVO';

-- Índice para búsquedas por método de pago
CREATE INDEX IF NOT EXISTS idx_reservas_metodo_pago ON reservas(metodo_pago);
