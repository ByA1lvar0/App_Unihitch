-- =====================================================
-- MIGRACIÓN: Fix FK Transacción
-- =====================================================

-- Agregar columna para vincular con comprobante_recarga
ALTER TABLE transaccion 
ADD COLUMN IF NOT EXISTS id_comprobante_recarga INTEGER REFERENCES comprobante_recarga(id);

COMMENT ON COLUMN transaccion.id_comprobante_recarga IS 'ID del comprobante de recarga (si aplica)';
