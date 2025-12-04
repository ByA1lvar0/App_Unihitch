-- =====================================================
-- MIGRACIÓN: Sistema de Bloqueo y Última Conexión
-- =====================================================

-- Tabla para gestionar usuarios bloqueados
CREATE TABLE IF NOT EXISTS usuario_bloqueado (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
    id_usuario_bloqueado INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
    fecha_bloqueo TIMESTAMP DEFAULT NOW(),
    UNIQUE(id_usuario, id_usuario_bloqueado),
    CHECK (id_usuario != id_usuario_bloqueado)
);

-- Agregar columna de última conexión a usuario
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS ultima_conexion TIMESTAMP DEFAULT NOW();

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_usuario_bloqueado_usuario ON usuario_bloqueado(id_usuario);
CREATE INDEX IF NOT EXISTS idx_usuario_bloqueado_bloqueado ON usuario_bloqueado(id_usuario_bloqueado);
CREATE INDEX IF NOT EXISTS idx_usuario_ultima_conexion ON usuario(ultima_conexion);

-- Comentarios
COMMENT ON TABLE usuario_bloqueado IS 'Gestiona la lista de usuarios bloqueados por cada usuario';
COMMENT ON COLUMN usuario.ultima_conexion IS 'Última vez que el usuario estuvo activo en la aplicación';

-- =====================================================
-- FIN DE MIGRACIÓN
-- =====================================================
