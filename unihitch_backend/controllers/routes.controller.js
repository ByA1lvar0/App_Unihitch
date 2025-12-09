const pool = require('../config/db');
const routeService = require('../services/route.service');

/**
 * Obtener ruta de un viaje específico
 */
const getRouteByTrip = async (req, res) => {
    try {
        const { tripId } = req.params;

        const result = await pool.query(
            `SELECT r.*, v.origen, v.destino, v.estado as estado_viaje
             FROM rutas r
             JOIN viaje v ON r.id_viaje = v.id
             WHERE r.id_viaje = $1`,
            [tripId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Ruta no encontrada' });
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error obteniendo ruta:', error);
        res.status(500).json({ error: 'Error al obtener ruta' });
    }
};

/**
 * Crear o actualizar ruta para un viaje
 */
const createOrUpdateRoute = async (req, res) => {
    try {
        const { id_viaje, origen, destino } = req.body;

        // Validar que el viaje existe
        const tripResult = await pool.query(
            'SELECT id FROM viaje WHERE id = $1',
            [id_viaje]
        );

        if (tripResult.rows.length === 0) {
            return res.status(404).json({ error: 'Viaje no encontrado' });
        }

        // Calcular ruta usando el servicio
        const routeData = await routeService.calculateRoute(origen, destino);

        // Verificar si ya existe una ruta para este viaje
        const existingRoute = await pool.query(
            'SELECT id FROM rutas WHERE id_viaje = $1',
            [id_viaje]
        );

        let result;
        if (existingRoute.rows.length > 0) {
            // Actualizar ruta existente
            result = await pool.query(
                `UPDATE rutas 
                 SET coordenadas = $1, distancia_km = $2, duracion_minutos = $3, updated_at = NOW()
                 WHERE id_viaje = $4
                 RETURNING *`,
                [JSON.stringify(routeData.coordinates), routeData.distance, routeData.duration, id_viaje]
            );
        } else {
            // Crear nueva ruta
            result = await pool.query(
                `INSERT INTO rutas (id_viaje, coordenadas, distancia_km, duracion_minutos)
                 VALUES ($1, $2, $3, $4)
                 RETURNING *`,
                [id_viaje, JSON.stringify(routeData.coordinates), routeData.distance, routeData.duration]
            );
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error creando/actualizando ruta:', error);
        res.status(500).json({ error: 'Error al procesar ruta', details: error.message });
    }
};

/**
 * Obtener todas las rutas de viajes activos
 */
const getActiveRoutes = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT r.*, v.origen, v.destino, v.estado, v.fecha_hora,
                    u.nombre as conductor_nombre
             FROM rutas r
             JOIN viaje v ON r.id_viaje = v.id
             JOIN usuario u ON v.id_conductor = u.id
             WHERE v.estado IN ('DISPONIBLE', 'EN_CURSO')
             ORDER BY v.fecha_hora DESC`
        );

        res.json(result.rows);
    } catch (error) {
        console.error('Error obteniendo rutas activas:', error);
        res.status(500).json({ error: 'Error al obtener rutas activas' });
    }
};

/**
 * Calcular ruta entre dos puntos (sin guardar)
 */
const calculateRoutePreview = async (req, res) => {
    try {
        const { origen, destino } = req.body;

        if (!origen || !destino || !origen.lat || !origen.lng || !destino.lat || !destino.lng) {
            return res.status(400).json({ error: 'Origen y destino con lat/lng son requeridos' });
        }

        const routeData = await routeService.calculateRoute(origen, destino);
        res.json(routeData);
    } catch (error) {
        console.error('Error calculando preview de ruta:', error);
        res.status(500).json({ error: 'Error al calcular ruta' });
    }
};

module.exports = {
    getRouteByTrip,
    createOrUpdateRoute,
    getActiveRoutes,
    calculateRoutePreview
};
