-- Agregar columnas a la tabla usuario
ALTER TABLE usuario 
ADD COLUMN IF NOT EXISTS rol VARCHAR(20) DEFAULT 'USER',
ADD COLUMN IF NOT EXISTS verificado BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS codigo_universitario VARCHAR(20);

-- Crear tabla para mensajes de la comunidad
CREATE TABLE IF NOT EXISTS mensaje_comunidad (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuario(id),
    id_universidad INTEGER REFERENCES universidad(id),
    mensaje TEXT NOT NULL,
    fecha_envio TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear un usuario admin por defecto (opcional, para pruebas)
-- La contraseña es 'admin123' (hash bcrypt aproximado para pruebas, o se puede actualizar luego)
-- INSERT INTO usuario (nombre, correo, password, rol, verificado, id_universidad) 
-- VALUES ('Admin', 'admin@unihitch.com', '$2b$10$YourHashedPasswordHere', 'ADMIN', TRUE, 1)
-- ON CONFLICT (correo) DO NOTHING;
