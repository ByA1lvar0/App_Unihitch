-- =====================================================
-- SCRIPT DE BASE DE DATOS PARA UNIHITCH
-- =====================================================
-- Ejecuta este script en PostgreSQL para crear todas las tablas necesarias
-- psql -U postgres -d unihitch_db -f database_setup.sql

-- =====================================================
-- TABLA: UNIVERSIDAD
-- =====================================================
CREATE TABLE IF NOT EXISTS universidad (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(50),
    pais VARCHAR(50) DEFAULT 'Perú',
    activo BOOLEAN DEFAULT TRUE
);

-- Universidades de Piura (Según tu app)
INSERT INTO universidad (nombre, ciudad) VALUES
('Universidad de Piura (UDEP)', 'Piura'),
('Universidad Nacional de Piura (UNP)', 'Piura'),
('Universidad César Vallejo (UCV)', 'Piura'),
('Universidad Privada del Norte (UPN)', 'Piura'),
('Universidad de San Martín de Porres', 'Piura');

-- =====================================================
-- TABLA: USUARIO
-- =====================================================
CREATE TABLE IF NOT EXISTS usuario (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    id_universidad INTEGER REFERENCES universidad(id),
    carrera VARCHAR(100),
    rol VARCHAR(20) DEFAULT 'estudiante',
    foto_perfil TEXT,
    calificacion_promedio DECIMAL(3,2) DEFAULT 0.00,
    total_viajes INTEGER DEFAULT 0,
    total_ahorrado DECIMAL(10,2) DEFAULT 0.00,
    verificado BOOLEAN DEFAULT FALSE,
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA: VIAJE
-- =====================================================
CREATE TABLE IF NOT EXISTS viaje (
    id SERIAL PRIMARY KEY,
    id_conductor INTEGER REFERENCES usuario(id) NOT NULL,
    origen VARCHAR(200) NOT NULL,
    destino VARCHAR(200) NOT NULL,
    fecha_hora TIMESTAMP NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    asientos_disponibles INTEGER NOT NULL,
    asientos_totales INTEGER NOT NULL,
    descripcion TEXT,
    estado VARCHAR(20) DEFAULT 'DISPONIBLE',
    -- Estados: DISPONIBLE, EN_CURSO, COMPLETADO, CANCELADO
    preferencias JSONB,
    -- Ejemplo: {"musica": "pop", "clima": "aire_acondicionado", "conversacion": "normal"}
    id_vehiculo INTEGER,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA: RESERVA
-- =====================================================
CREATE TABLE IF NOT EXISTS reserva (
    id SERIAL PRIMARY KEY,
    id_viaje INTEGER REFERENCES viaje(id) NOT NULL,
    id_pasajero INTEGER REFERENCES usuario(id) NOT NULL,
    estado VARCHAR(20) DEFAULT 'PENDIENTE',
    -- Estados: PENDIENTE, CONFIRMADA, COMPLETADA, CANCELADA
    fecha_reserva TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    calificacion_pasajero INTEGER,
    calificacion_conductor INTEGER,
    comentario_pasajero TEXT,
    comentario_conductor TEXT,
    precio_final DECIMAL(10,2)
);

-- =====================================================
-- TABLA: VEHICULO
-- =====================================================
CREATE TABLE IF NOT EXISTS vehiculo (
    id SERIAL PRIMARY KEY,
    id_conductor INTEGER REFERENCES usuario(id) NOT NULL,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    año INTEGER,
    placa VARCHAR(20) UNIQUE NOT NULL,
    color VARCHAR(30),
    capacidad INTEGER NOT NULL,
    foto TEXT,
    soat_vigente BOOLEAN DEFAULT FALSE,
    soat_vencimiento DATE,
    revision_tecnica BOOLEAN DEFAULT FALSE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA: WALLET (Billetera Virtual)
-- =====================================================
CREATE TABLE IF NOT EXISTS wallet (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuario(id) NOT NULL UNIQUE,
    saldo DECIMAL(10,2) DEFAULT 0.00,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA: TRANSACCION
-- =====================================================
CREATE TABLE IF NOT EXISTS transaccion (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuario(id) NOT NULL,
    tipo VARCHAR(20) NOT NULL,
    -- Tipos: RECARGA, PAGO_VIAJE, RETIRO, REEMBOLSO
    monto DECIMAL(10,2) NOT NULL,
    descripcion TEXT,
    metodo_pago VARCHAR(50),
    estado VARCHAR(20) DEFAULT 'COMPLETADA',
    fecha_transaccion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA: NOTIFICACION
-- =====================================================
CREATE TABLE IF NOT EXISTS notificacion (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuario(id) NOT NULL,
    titulo VARCHAR(100) NOT NULL,
    mensaje TEXT NOT NULL,
    tipo VARCHAR(30) NOT NULL,
    -- Tipos: VIAJE_CONFIRMADO, PAGO_PROCESADO, NUEVA_CALIFICACION, CANCELACION, URGENTE
    leida BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA: EMERGENCIA
-- =====================================================
CREATE TABLE IF NOT EXISTS emergencia (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuario(id) NOT NULL,
    ubicacion_lat DECIMAL(10,8),
    ubicacion_lng DECIMAL(11,8),
    mensaje TEXT,
    contactos_notificados TEXT[],
    estado VARCHAR(20) DEFAULT 'ACTIVA',
    fecha_activacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA: CONTACTO_EMERGENCIA
-- =====================================================
CREATE TABLE IF NOT EXISTS contacto_emergencia (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuario(id) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    relacion VARCHAR(50),
    activo BOOLEAN DEFAULT TRUE
);

-- =====================================================
-- TABLA: CONFIGURACION_EMERGENCIA
-- =====================================================
CREATE TABLE IF NOT EXISTS configuracion_emergencia (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuario(id) NOT NULL UNIQUE,
    auto_envio_ubicacion BOOLEAN DEFAULT FALSE,
    notificar_universidad BOOLEAN DEFAULT TRUE,
    grabar_audio BOOLEAN DEFAULT FALSE,
    alertas_velocidad BOOLEAN DEFAULT FALSE
);

-- =====================================================
-- TABLA: CHAT
-- =====================================================
CREATE TABLE IF NOT EXISTS chat (
    id SERIAL PRIMARY KEY,
    id_usuario1 INTEGER REFERENCES usuario(id) NOT NULL,
    id_usuario2 INTEGER REFERENCES usuario(id) NOT NULL,
    ultimo_mensaje TEXT,
    fecha_ultimo_mensaje TIMESTAMP,
    no_leidos_usuario1 INTEGER DEFAULT 0,
    no_leidos_usuario2 INTEGER DEFAULT 0
);

-- =====================================================
-- TABLA: MENSAJE
-- =====================================================
CREATE TABLE IF NOT EXISTS mensaje (
    id SERIAL PRIMARY KEY,
    id_chat INTEGER REFERENCES chat(id) NOT NULL,
    id_remitente INTEGER REFERENCES usuario(id) NOT NULL,
    mensaje TEXT NOT NULL,
    leido BOOLEAN DEFAULT FALSE,
    fecha_envio TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA: BADGE (Logros/Insignias)
-- =====================================================
CREATE TABLE IF NOT EXISTS badge (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuario(id) NOT NULL,
    nombre_badge VARCHAR(50) NOT NULL,
    -- Nombres: TOP_RIDER, CINCO_ESTRELLAS, ECO_FRIENDLY, PUNTUAL, etc.
    fecha_obtencion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- INDICES PARA MEJORAR RENDIMIENTO
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_usuario_universidad ON usuario(id_universidad);
CREATE INDEX IF NOT EXISTS idx_viaje_conductor ON viaje(id_conductor);
CREATE INDEX IF NOT EXISTS idx_viaje_fecha ON viaje(fecha_hora);
CREATE INDEX IF NOT EXISTS idx_viaje_estado ON viaje(estado);
CREATE INDEX IF NOT EXISTS idx_reserva_viaje ON reserva(id_viaje);
CREATE INDEX IF NOT EXISTS idx_reserva_pasajero ON reserva(id_pasajero);
CREATE INDEX IF NOT EXISTS idx_notificacion_usuario ON notificacion(id_usuario);
CREATE INDEX IF NOT EXISTS idx_chat_usuarios ON chat(id_usuario1, id_usuario2);

-- =====================================================
-- FUNCIONES Y TRIGGERS
-- =====================================================

-- Trigger para crear wallet automáticamente cuando se crea un usuario
CREATE OR REPLACE FUNCTION crear_wallet_usuario()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO wallet (id_usuario) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_crear_wallet
AFTER INSERT ON usuario
FOR EACH ROW
EXECUTE FUNCTION crear_wallet_usuario();

-- =====================================================
-- VISTAS ÚTILES
-- =====================================================

-- Vista de viajes disponibles con información del conductor
CREATE OR REPLACE VIEW viajes_disponibles AS
SELECT 
    v.*,
    u.nombre as conductor_nombre,
    u.telefono as conductor_telefono,
    u.calificacion_promedio,
    uni.nombre as universidad
FROM viaje v
JOIN usuario u ON v.id_conductor = u.id
LEFT JOIN universidad uni ON u.id_universidad = uni.id
WHERE v.estado = 'DISPONIBLE' AND v.fecha_hora > NOW()
ORDER BY v.fecha_hora;

-- Vista de perfil de usuario con estadísticas
CREATE OR REPLACE VIEW perfil_usuario AS
SELECT 
    u.*,
    uni.nombre as nombre_universidad,
    w.saldo,
    COUNT(DISTINCT r.id) as total_reservas,
    COUNT(DISTINCT CASE WHEN v.estado = 'COMPLETADO' THEN v.id END) as viajes_completados
FROM usuario u
LEFT JOIN universidad uni ON u.id_universidad = uni.id
LEFT JOIN wallet w ON u.id = w.id_usuario
LEFT JOIN reserva r ON u.id = r.id_pasajero
LEFT JOIN viaje v ON u.id = v.id_conductor
GROUP BY u.id, uni.nombre, w.saldo;

-- =====================================================
-- COMENTARIOS
-- =====================================================

COMMENT ON TABLE usuario IS 'Usuarios de la aplicación (conductores y pasajeros)';
COMMENT ON TABLE viaje IS 'Viajes ofrecidos por conductores';
COMMENT ON TABLE reserva IS 'Reservas de pasajeros en viajes';
COMMENT ON TABLE wallet IS 'Billeteras virtuales de los usuarios';
COMMENT ON TABLE notificacion IS 'Notificaciones del sistema para usuarios';
COMMENT ON TABLE emergencia IS 'Alertas de emergencia activadas';
COMMENT ON TABLE chat IS 'Chats entre usuarios';
COMMENT ON TABLE mensaje IS 'Mensajes en los chats';

-- =====================================================
-- FIN DEL SCRIPT
-- =====================================================

