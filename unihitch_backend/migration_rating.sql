CREATE TABLE IF NOT EXISTS calificacion (
  id SERIAL PRIMARY KEY,
  id_viaje INTEGER REFERENCES viaje(id),
  id_autor INTEGER REFERENCES usuario(id),
  id_destinatario INTEGER REFERENCES usuario(id),
  puntuacion INTEGER CHECK (puntuacion >= 1 AND puntuacion <= 5),
  comentario TEXT,
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add column for average rating to user table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'usuario' AND column_name = 'calificacion_promedio') THEN
        ALTER TABLE usuario ADD COLUMN calificacion_promedio NUMERIC(3, 2) DEFAULT 5.00;
    END IF;
END $$;
