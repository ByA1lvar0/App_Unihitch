const pool = require('../config/db');

const getPendingUsers = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT u.id, u.nombre, u.correo, u.codigo_universitario, u.id_universidad, uni.nombre as universidad 
       FROM usuario u 
       LEFT JOIN universidad uni ON u.id_universidad = uni.id 
       WHERE u.verificado = false AND u.rol = 'USER' 
       ORDER BY uni.nombre, u.id DESC`
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener usuarios pendientes' });
    }
};

const verifyUser = async (req, res) => {
    try {
        const { userId } = req.params;
        await pool.query('UPDATE usuario SET verificado = true WHERE id = $1', [userId]);
        res.json({ success: true, message: 'Usuario verificado correctamente' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al verificar usuario' });
    }
};

const addAdmin = async (req, res) => {
    try {
        const { email } = req.body;

        const user = await pool.query('SELECT * FROM usuario WHERE correo = $1', [email]);
        if (user.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        await pool.query('UPDATE usuario SET rol = \'ADMIN\', verificado = true WHERE correo = $1', [email]);
        res.json({ success: true, message: 'Usuario promovido a administrador' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al agregar administrador' });
    }
};

const getUsers = async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT id, nombre, correo, id_universidad, verificado FROM usuario WHERE rol = \'USER\' ORDER BY nombre'
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener usuarios' });
    }
};

const deleteUser = async (req, res) => {
    try {
        const { userId } = req.params;

        // Eliminar mensajes de comunidad del usuario
        await pool.query('DELETE FROM mensaje_comunidad WHERE id_usuario = $1', [userId]);

        // Eliminar usuario
        await pool.query('DELETE FROM usuario WHERE id = $1', [userId]);

        res.json({ message: 'Usuario eliminado correctamente' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al eliminar usuario' });
    }
};

const changeUniversity = async (req, res) => {
    try {
        const { userId, universidadId } = req.body;

        // Actualizar universidad y verificar usuario
        await pool.query(
            'UPDATE usuario SET id_universidad = $1, verificado = true WHERE id = $2',
            [universidadId, userId]
        );

        res.json({ message: 'Usuario agregado a la comunidad' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al agregar usuario' });
    }
};

module.exports = { getPendingUsers, verifyUser, addAdmin, getUsers, deleteUser, changeUniversity };
