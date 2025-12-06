CREATE TABLE IF NOT EXISTS alerta_emergencia (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuario(id),
    latitud DECIMAL(10, 8) NOT NULL,
    longitud DECIMAL(11, 8) NOT NULL,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'ENVIADA' -- ENVIADA, RECIBIDA, ATENDIDA
);

CREATE INDEX IF NOT EXISTS idx_alerta_usuario ON alerta_emergencia(id_usuario);
