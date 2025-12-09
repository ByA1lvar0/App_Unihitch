const pool = require('../config/db');

/**
 * Bloquear un usuario
 */
const blockUser = async (req, res) => {
    try {
        const userId = req.user.id;
        const { id_usuario_bloqueado } = req.body;

        if (userId === id_usuario_bloqueado) {
            return res.status(400).json({ error: 'No puedes bloquearte a ti mismo' });
        }

        // Verificar que el usuario a bloquear existe
        const userExists = await pool.query(
            'SELECT id FROM usuario WHERE id = $1',
            [id_usuario_bloqueado]
        );

        if (userExists.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // Insertar bloqueo (si ya existe, no hace nada por el UNIQUE constraint)
        await pool.query(
            `INSERT INTO usuario_bloqueado (id_usuario, id_usuario_bloqueado) 
             VALUES ($1, $2) 
             ON CONFLICT (id_usuario, id_usuario_bloqueado) DO NOTHING`,
            [userId, id_usuario_bloqueado]
        );

        res.json({ mensaje: 'Usuario bloqueado exitosamente' });
    } catch (error) {
        console.error('Error bloqueando usuario:', error);
        res.status(500).json({ error: 'Error al bloquear usuario' });
    }
};

/**
 * Desbloquear un usuario
 */
const unblockUser = async (req, res) => {
    try {
        const userId = req.user.id;
        const { id_usuario_bloqueado } = req.body;

        await pool.query(
            'DELETE FROM usuario_bloqueado WHERE id_usuario = $1 AND id_usuario_bloqueado = $2',
            [userId, id_usuario_bloqueado]
        );

        res.json({ mensaje: 'Usuario desbloqueado exitosamente' });
    } catch (error) {
        console.error('Error desbloqueando usuario:', error);
        res.status(500).json({ error: 'Error al desbloquear usuario' });
    }
};

/**
 * Obtener lista de usuarios bloqueados
 */
const getBlockedUsers = async (req, res) => {
    try {
        const userId = req.user.id;

        const result = await pool.query(
            `SELECT u.id, u.nombre, u.correo, u.foto_perfil, ub.fecha_bloqueo
             FROM usuario_bloqueado ub
             JOIN usuario u ON ub.id_usuario_bloqueado = u.id
             WHERE ub.id_usuario = $1
             ORDER BY ub.fecha_bloqueo DESC`,
            [userId]
        );

        res.json(result.rows);
    } catch (error) {
        console.error('Error obteniendo usuarios bloqueados:', error);
        res.status(500).json({ error: 'Error al obtener usuarios bloqueados' });
    }
};

/**
 * Verificar si un usuario está bloqueado
 */
const isUserBlocked = async (req, res) => {
    try {
        const userId = req.user.id;
        const { id_otro_usuario } = req.params;

        const result = await pool.query(
            `SELECT EXISTS(
                SELECT 1 FROM usuario_bloqueado 
                WHERE (id_usuario = $1 AND id_usuario_bloqueado = $2)
                   OR (id_usuario = $2 AND id_usuario_bloqueado = $1)
            ) as bloqueado`,
            [userId, id_otro_usuario]
        );

        res.json({ bloqueado: result.rows[0].bloqueado });
    } catch (error) {
        console.error('Error verificando bloqueo:', error);
        res.status(500).json({ error: 'Error al verificar bloqueo' });
    }
};

/**
 * Actualizar última conexión del usuario
 */
const updateLastSeen = async (req, res) => {
    try {
        const userId = req.user.id;

        await pool.query(
            'UPDATE usuario SET ultima_conexion = NOW() WHERE id = $1',
            [userId]
        );

        res.json({ mensaje: 'Última conexión actualizada' });
    } catch (error) {
        console.error('Error actualizando última conexión:', error);
        res.status(500).json({ error: 'Error al actualizar última conexión' });
    }
};

module.exports = {
    blockUser,
    unblockUser,
    getBlockedUsers,
    isUserBlocked,
    updateLastSeen
};
