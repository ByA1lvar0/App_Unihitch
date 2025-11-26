-- Migración: Sistema de Verificación de Email
-- Fecha: 2025-11-24

-- Tabla para códigos de verificación de email
CREATE TABLE IF NOT EXISTS codigos_verificacion_email (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuario(id) ON DELETE CASCADE,
    codigo VARCHAR(6) NOT NULL,
    email VARCHAR(255) NOT NULL,
    usado BOOLEAN DEFAULT FALSE,
    intentos_fallidos INTEGER DEFAULT 0,
    fecha_creacion TIMESTAMP DEFAULT NOW(),
    fecha_expiracion TIMESTAMP DEFAULT NOW() + INTERVAL '15 minutes',
    fecha_uso TIMESTAMP,
    ip_solicitud VARCHAR(45)
);

-- Agregar columnas de verificación de email al usuario
ALTER TABLE usuario
ADD COLUMN IF NOT EXISTS email_verificado BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS fecha_verificacion_email TIMESTAMP,
ADD COLUMN IF NOT EXISTS token_verificacion_email VARCHAR(255);

-- Tabla para registro de intentos de verificación
CREATE TABLE IF NOT EXISTS intentos_verificacion_email (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuario(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    codigo_ingresado VARCHAR(6),
    exitoso BOOLEAN DEFAULT FALSE,
    fecha_intento TIMESTAMP DEFAULT NOW(),
    ip_address VARCHAR(45)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_codigo_usuario ON codigos_verificacion_email(id_usuario);
CREATE INDEX IF NOT EXISTS idx_codigo_email ON codigos_verificacion_email(email);
CREATE INDEX IF NOT EXISTS idx_codigo_valido ON codigos_verificacion_email(usado, fecha_expiracion) 
WHERE usado = FALSE AND fecha_expiracion > NOW();
CREATE INDEX IF NOT EXISTS idx_usuario_email_verificado ON usuario(email_verificado);
CREATE INDEX IF NOT EXISTS idx_intentos_usuario ON intentos_verificacion_email(id_usuario);

-- Función para limpiar códigos expirados (ejecutar periódicamente)
CREATE OR REPLACE FUNCTION limpiar_codigos_expirados()
RETURNS void AS $$
BEGIN
    DELETE FROM codigos_verificacion_email 
    WHERE fecha_expiracion < NOW() - INTERVAL '1 day';
    
    DELETE FROM intentos_verificacion_email 
    WHERE fecha_intento < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;


-- Comentarios
COMMENT ON TABLE codigos_verificacion_email IS 'Códigos de 6 dígitos enviados por email para verificación';
COMMENT ON COLUMN codigos_verificacion_email.codigo IS 'Código de 6 dígitos numéricos';
COMMENT ON COLUMN codigos_verificacion_email.intentos_fallidos IS 'Contador de intentos fallidos para prevenir ataques de fuerza bruta';
COMMENT ON COLUMN usuario.email_verificado IS 'TRUE si el usuario verificó su email con el código';
