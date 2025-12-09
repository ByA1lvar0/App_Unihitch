const pool = require('../config/db');

const getTripHistory = async (req, res) => {
    try {
        const { userId } = req.params;

        // Obtener viajes como conductor
        const asDriver = await pool.query(
            `SELECT v.*, 
              COUNT(DISTINCT r.id) as total_pasajeros,
              COALESCE(AVG(c.puntuacion), 0) as calificacion_promedio
       FROM viaje v
       LEFT JOIN reserva r ON v.id = r.id_viaje AND r.estado = 'CONFIRMADA'
       LEFT JOIN calificacion c ON v.id = c.id_viaje AND c.id_destinatario = $1
       WHERE v.id_conductor = $1
       GROUP BY v.id
       ORDER BY v.fecha_hora DESC`,
            [userId]
        );

        // Obtener viajes como pasajero
        const asPassenger = await pool.query(
            `SELECT v.*, r.id as reserva_id, r.estado as reserva_estado, v.precio as monto_pagado,
              u.nombre as conductor_nombre, u.calificacion_promedio as conductor_rating,
              c.puntuacion as mi_calificacion
       FROM reserva r
       JOIN viaje v ON r.id_viaje = v.id
       JOIN usuario u ON v.id_conductor = u.id
       LEFT JOIN calificacion c ON v.id = c.id_viaje AND c.id_autor = $1
       WHERE r.id_pasajero = $1
       ORDER BY v.fecha_hora DESC`,
            [userId]
        );

        res.json({
            as_driver: asDriver.rows,
            as_passenger: asPassenger.rows
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener historial de viajes' });
    }
};

const getUserStatistics = async (req, res) => {
    try {
        const { userId } = req.params;

        // Estadísticas como conductor (Viajes y Dinero)
        const driverTripsStats = await pool.query(
            `SELECT 
         COUNT(DISTINCT v.id) as total_viajes,
         COUNT(DISTINCT r.id) as total_pasajeros,
         COALESCE(SUM(CASE WHEN r.id IS NOT NULL THEN v.precio ELSE 0 END), 0) as dinero_ganado
       FROM viaje v
       LEFT JOIN reserva r ON v.id = r.id_viaje AND r.estado = 'CONFIRMADA'
       WHERE v.id_conductor = $1`,
            [userId]
        );

        // Estadísticas como conductor (Calificación)
        const driverRatingStats = await pool.query(
            `SELECT COALESCE(AVG(puntuacion), 0) as calificacion_promedio
             FROM calificacion
             WHERE id_destinatario = $1`,
            [userId]
        );

        // Estadísticas como pasajero
        const passengerStats = await pool.query(
            `SELECT 
         COUNT(DISTINCT r.id) as total_viajes,
         COALESCE(SUM(v.precio), 0) as dinero_gastado
       FROM reserva r
       JOIN viaje v ON r.id_viaje = v.id
       WHERE r.id_pasajero = $1 AND r.estado = 'CONFIRMADA'`,
            [userId]
        );

        // Calcular CO2 ahorrado (estimación: 120g CO2 por km en auto vs 30g en carpooling)
        // Asumimos 10km promedio por viaje
        const totalTrips = parseInt(driverTripsStats.rows[0].total_viajes) + parseInt(passengerStats.rows[0].total_viajes);
        const co2Saved = totalTrips * 10 * 0.09; // kg de CO2

        // Viajes por mes (últimos 6 meses)
        const tripsByMonth = await pool.query(
            `SELECT 
         TO_CHAR(v.fecha_hora, 'YYYY-MM') as mes,
         COUNT(DISTINCT v.id) as total
       FROM viaje v
       LEFT JOIN reserva r ON v.id = r.id_viaje
       WHERE (v.id_conductor = $1 OR r.id_pasajero = $1)
         AND v.fecha_hora >= NOW() - INTERVAL '6 months'
       GROUP BY TO_CHAR(v.fecha_hora, 'YYYY-MM')
       ORDER BY mes DESC`,
            [userId]
        );

        res.json({
            as_driver: {
                total_trips: parseInt(driverTripsStats.rows[0].total_viajes),
                total_passengers: parseInt(driverTripsStats.rows[0].total_pasajeros),
                money_earned: parseFloat(driverTripsStats.rows[0].dinero_ganado),
                average_rating: parseFloat(driverRatingStats.rows[0].calificacion_promedio).toFixed(2)
            },
            as_passenger: {
                total_trips: parseInt(passengerStats.rows[0].total_viajes),
                money_spent: parseFloat(passengerStats.rows[0].dinero_gastado)
            },
            overall: {
                total_trips: totalTrips,
                co2_saved_kg: co2Saved.toFixed(2),
                trips_by_month: tripsByMonth.rows
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener estadísticas' });
    }
};

module.exports = { getTripHistory, getUserStatistics };
