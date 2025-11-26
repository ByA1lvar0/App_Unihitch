const pool = require('../config/db');

// Conductores favoritos
const addFavoriteDriver = async (req, res) => {
    try {
        const { userId, driverId } = req.body;

        const result = await pool.query(
            'INSERT INTO conductor_favorito (id_usuario, id_conductor) VALUES ($1, $2) ON CONFLICT DO NOTHING RETURNING *',
            [userId, driverId]
        );

        res.json({ mensaje: 'Conductor agregado a favoritos', favorito: result.rows[0] });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al agregar favorito' });
    }
};

const removeFavoriteDriver = async (req, res) => {
    try {
        const { userId, driverId } = req.params;

        await pool.query(
            'DELETE FROM conductor_favorito WHERE id_usuario = $1 AND id_conductor = $2',
            [userId, driverId]
        );

        res.json({ mensaje: 'Conductor eliminado de favoritos' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al eliminar favorito' });
    }
};

const getFavoriteDrivers = async (req, res) => {
    try {
        const { userId } = req.params;

        const result = await pool.query(
            `SELECT u.id, u.nombre, u.correo, u.telefono, u.calificacion_promedio, u.foto_perfil,
              cf.fecha_agregado
       FROM conductor_favorito cf
       JOIN usuario u ON cf.id_conductor = u.id
       WHERE cf.id_usuario = $1
       ORDER BY cf.fecha_agregado DESC`,
            [userId]
        );

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener conductores favoritos' });
    }
};

// Rutas favoritas
const addFavoriteRoute = async (req, res) => {
    try {
        const { userId, origen, destino, nombre } = req.body;

        const result = await pool.query(
            'INSERT INTO ruta_favorita (id_usuario, origen, destino, nombre) VALUES ($1, $2, $3, $4) RETURNING *',
            [userId, origen, destino, nombre || `${origen} → ${destino}`]
        );

        res.json({ mensaje: 'Ruta agregada a favoritos', ruta: result.rows[0] });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al agregar ruta favorita' });
    }
};

const removeFavoriteRoute = async (req, res) => {
    try {
        const { routeId } = req.params;

        await pool.query('DELETE FROM ruta_favorita WHERE id = $1', [routeId]);

        res.json({ mensaje: 'Ruta eliminada de favoritos' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al eliminar ruta favorita' });
    }
};

const getFavoriteRoutes = async (req, res) => {
    try {
        const { userId } = req.params;

        const result = await pool.query(
            'SELECT * FROM ruta_favorita WHERE id_usuario = $1 ORDER BY fecha_agregado DESC',
            [userId]
        );

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener rutas favoritas' });
    }
};

module.exports = {
    addFavoriteDriver,
    removeFavoriteDriver,
    getFavoriteDrivers,
    addFavoriteRoute,
    removeFavoriteRoute,
    getFavoriteRoutes
};
