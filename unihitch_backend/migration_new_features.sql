-- Migration for Emergency Contacts, Notifications Enhancement, and Carpooling
-- Run with: node run_new_features_migration.js

-- 1. Emergency Contacts System
CREATE TABLE IF NOT EXISTS contactos_emergencia (
  id SERIAL PRIMARY KEY,
  id_usuario INTEGER REFERENCES usuario(id) ON DELETE CASCADE,
  nombre VARCHAR(100) NOT NULL,
  telefono VARCHAR(20) NOT NULL,
  relacion VARCHAR(50),
  es_principal BOOLEAN DEFAULT false,
  fecha_creacion TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS configuracion_emergencia (
  id SERIAL PRIMARY KEY,
  id_usuario INTEGER REFERENCES usuario(id) ON DELETE CASCADE UNIQUE,
  auto_envio_ubicacion BOOLEAN DEFAULT false,
  notificar_universidad BOOLEAN DEFAULT true,
  grabar_audio BOOLEAN DEFAULT true,
  alertas_velocidad BOOLEAN DEFAULT false,
  velocidad_maxima INTEGER DEFAULT 80,
  fecha_actualizacion TIMESTAMP DEFAULT NOW()
);

-- 2. Enhanced Notifications System
CREATE TABLE IF NOT EXISTS notificaciones (
  id SERIAL PRIMARY KEY,
  id_usuario INTEGER REFERENCES usuario(id) ON DELETE CASCADE,
  titulo VARCHAR(200),
  mensaje TEXT,
  fecha_creacion TIMESTAMP DEFAULT NOW()
);

ALTER TABLE notificaciones 
  ADD COLUMN IF NOT EXISTS tipo VARCHAR(50) DEFAULT 'GENERAL',
  ADD COLUMN IF NOT EXISTS prioridad VARCHAR(20) DEFAULT 'NORMAL',
  ADD COLUMN IF NOT EXISTS datos_adicionales JSONB,
  ADD COLUMN IF NOT EXISTS leida BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS fecha_lectura TIMESTAMP;

-- 3. Carpooling/Group Trips System
CREATE TABLE IF NOT EXISTS grupos_viaje (
  id SERIAL PRIMARY KEY,
  id_organizador INTEGER REFERENCES usuario(id) ON DELETE CASCADE,
  ruta_comun VARCHAR(200) NOT NULL,
  origen VARCHAR(200),
  destino VARCHAR(200),
  horario_preferido TIME,
  dias_semana VARCHAR(50), -- 'LUN,MAR,MIE,JUE,VIE'
  tipo_grupo VARCHAR(50) DEFAULT 'CUALQUIERA', -- 'MISMA_CARRERA', 'MISMA_UNIVERSIDAD', 'CUALQUIERA'
  costo_total DECIMAL(10,2),
  num_pasajeros INTEGER DEFAULT 4,
  costo_por_persona DECIMAL(10,2),
  descripcion TEXT,
  estado VARCHAR(20) DEFAULT 'ABIERTO', -- 'ABIERTO', 'COMPLETO', 'CERRADO'
  fecha_creacion TIMESTAMP DEFAULT NOW(),
  fecha_actualizacion TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS miembros_grupo (
  id SERIAL PRIMARY KEY,
  id_grupo INTEGER REFERENCES grupos_viaje(id) ON DELETE CASCADE,
  id_usuario INTEGER REFERENCES usuario(id) ON DELETE CASCADE,
  fecha_union TIMESTAMP DEFAULT NOW(),
  estado VARCHAR(20) DEFAULT 'ACTIVO', -- 'ACTIVO', 'INACTIVO'
  UNIQUE(id_grupo, id_usuario)
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_contactos_emergencia_usuario ON contactos_emergencia(id_usuario);
CREATE INDEX IF NOT EXISTS idx_config_emergencia_usuario ON configuracion_emergencia(id_usuario);
CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario_leida ON notificaciones(id_usuario, leida);
CREATE INDEX IF NOT EXISTS idx_notificaciones_tipo ON notificaciones(tipo);
CREATE INDEX IF NOT EXISTS idx_grupos_viaje_estado ON grupos_viaje(estado);
CREATE INDEX IF NOT EXISTS idx_grupos_viaje_organizador ON grupos_viaje(id_organizador);
CREATE INDEX IF NOT EXISTS idx_miembros_grupo_usuario ON miembros_grupo(id_usuario);

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Migration completed successfully!';
  RAISE NOTICE '- Emergency contacts tables created';
  RAISE NOTICE '- Notifications enhanced';
  RAISE NOTICE '- Carpooling tables created';
  RAISE NOTICE '- Indexes created for performance';
END $$;
