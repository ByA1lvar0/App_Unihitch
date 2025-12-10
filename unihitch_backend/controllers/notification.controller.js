const pool = require('../config/db');

const getNotifications = async (req, res) => {
    try {
        const { userId } = req.params;
        const result = await pool.query(
            'SELECT * FROM notificacion WHERE id_usuario = $1 ORDER BY fecha_creacion DESC',
            [userId]
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener notificaciones' });
    }
};

const createNotification = async (req, res) => {
    try {
        const { id_usuario, titulo, mensaje, tipo } = req.body;
        const result = await pool.query(
            'INSERT INTO notificacion (id_usuario, titulo, mensaje, tipo) VALUES ($1, $2, $3, $4) RETURNING *',
            [id_usuario, titulo, mensaje, tipo]
        );
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al crear notificación' });
    }
};

const markAsRead = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            'UPDATE notificacion SET leido = true WHERE id = $1 RETURNING *',
            [id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Notificación no encontrada' });
        }
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al marcar notificación' });
    }
};

const markAllAsRead = async (req, res) => {
    try {
        const { userId } = req.params;
        const result = await pool.query(
            'UPDATE notificacion SET leido = true WHERE id_usuario = $1 RETURNING *',
            [userId]
        );
        res.json({ success: true, count: result.rowCount });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al marcar notificaciones como leídas' });
    }
};

module.exports = { getNotifications, createNotification, markAsRead, markAllAsRead };
