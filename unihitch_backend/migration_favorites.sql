-- Tabla para conductores favoritos
CREATE TABLE IF NOT EXISTS conductor_favorito (
  id SERIAL PRIMARY KEY,
  id_usuario INTEGER REFERENCES usuario(id) ON DELETE CASCADE,
  id_conductor INTEGER REFERENCES usuario(id) ON DELETE CASCADE,
  fecha_agregado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(id_usuario, id_conductor)
);

-- Tabla para rutas favoritas
CREATE TABLE IF NOT EXISTS ruta_favorita (
  id SERIAL PRIMARY KEY,
  id_usuario INTEGER REFERENCES usuario(id) ON DELETE CASCADE,
  origen VARCHAR(255) NOT NULL,
  destino VARCHAR(255) NOT NULL,
  nombre VARCHAR(100),
  fecha_agregado TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_conductor_favorito_usuario ON conductor_favorito(id_usuario);
CREATE INDEX IF NOT EXISTS idx_ruta_favorita_usuario ON ruta_favorita(id_usuario);
