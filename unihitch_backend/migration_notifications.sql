-- =====================================================
-- MIGRACIÓN: Tabla de Notificaciones
-- =====================================================

CREATE TABLE IF NOT EXISTS notificacion (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuario(id) NOT NULL,
    titulo VARCHAR(100) NOT NULL,
    mensaje TEXT NOT NULL,
    tipo VARCHAR(20) DEFAULT 'SYSTEM', -- 'SYSTEM', 'TRIP', 'WALLET', etc.
    leido BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notificacion_usuario ON notificacion(id_usuario);
CREATE INDEX IF NOT EXISTS idx_notificacion_leido ON notificacion(leido);

COMMENT ON TABLE notificacion IS 'Notificaciones del sistema para los usuarios';
