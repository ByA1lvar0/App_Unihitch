-- Tabla de referidos
CREATE TABLE IF NOT EXISTS referido (
  id SERIAL PRIMARY KEY,
  id_referidor INTEGER REFERENCES usuario(id) ON DELETE CASCADE,
  id_referido INTEGER REFERENCES usuario(id) ON DELETE CASCADE,
  codigo_referido VARCHAR(20) NOT NULL,
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  recompensa_otorgada BOOLEAN DEFAULT FALSE,
  monto_recompensa NUMERIC(10, 2) DEFAULT 10.00,
  UNIQUE(id_referidor, id_referido)
);

-- Agregar columna de código de referido a usuario si no existe
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='usuario' AND column_name='codigo_referido') THEN
    ALTER TABLE usuario ADD COLUMN codigo_referido VARCHAR(20) UNIQUE;
  END IF;
END $$;

-- Índices
CREATE INDEX IF NOT EXISTS idx_referido_referidor ON referido(id_referidor);
CREATE INDEX IF NOT EXISTS idx_referido_codigo ON referido(codigo_referido);
