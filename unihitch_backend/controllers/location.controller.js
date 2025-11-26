const pool = require('../config/db');

const updateLocation = async (req, res) => {
    try {
        const { id_usuario, id_viaje, latitud, longitud } = req.body;

        // Actualizar ubicación general del usuario
        await pool.query(
            'UPDATE usuario SET ubicacion_lat = $1, ubicacion_lng = $2, ubicacion_actualizada = NOW() WHERE id = $3',
            [latitud, longitud, id_usuario]
        );

        // Si hay un viaje activo, actualizar en la tabla de tracking
        if (id_viaje) {
            await pool.query(
                `INSERT INTO ubicacion_viaje (id_viaje, id_usuario, latitud, longitud, fecha_actualizacion)
         VALUES ($1, $2, $3, $4, NOW())
         ON CONFLICT (id_viaje, id_usuario) 
         DO UPDATE SET latitud = $3, longitud = $4, fecha_actualizacion = NOW()`,
                [id_viaje, id_usuario, latitud, longitud]
            );
        }

        res.json({ success: true, mensaje: 'Ubicación actualizada' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al actualizar ubicación' });
    }
};

const getTripParticipantsLocations = async (req, res) => {
    try {
        const { tripId } = req.params;

        // Obtener información del viaje
        const viaje = await pool.query(
            'SELECT id_conductor FROM viaje WHERE id = $1',
            [tripId]
        );

        if (viaje.rows.length === 0) {
            return res.status(404).json({ error: 'Viaje no encontrado' });
        }

        const id_conductor = viaje.rows[0].id_conductor;

        // Obtener pasajeros del viaje
        const pasajeros = await pool.query(
            `SELECT DISTINCT r.id_pasajero
       FROM reserva r
       WHERE r.id_viaje = $1 AND r.estado = 'CONFIRMADA'`,
            [tripId]
        );

        // Obtener ubicaciones recientes del conductor y pasajeros
        const ubicaciones = await pool.query(
            `SELECT 
         u.id,
         u.nombre,
         u.telefono,
         u.foto_perfil,
         CASE WHEN u.id = $2 THEN 'conductor' ELSE 'pasajero' END as rol,
         COALESCE(uv.latitud, u.ubicacion_lat) as latitud,
         COALESCE(uv.longitud, u.ubicacion_lng) as longitud,
         COALESCE(uv.fecha_actualizacion, u.ubicacion_actualizada) as ultima_actualizacion,
         CASE 
           WHEN COALESCE(uv.fecha_actualizacion, u.ubicacion_actualizada) > NOW() - INTERVAL '2 minutes' 
           THEN 'conectado' 
           ELSE 'desconectado' 
         END as estado_conexion
       FROM usuario u
       LEFT JOIN ubicacion_viaje uv ON uv.id_usuario = u.id AND uv.id_viaje = $1
       WHERE u.id = $2 OR u.id = ANY($3)`,
            [tripId, id_conductor, pasajeros.rows.map(p => p.id_pasajero)]
        );

        res.json({
            viaje_id: tripId,
            ubicaciones: ubicaciones.rows
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener ubicaciones' });
    }
};

module.exports = { updateLocation, getTripParticipantsLocations };
