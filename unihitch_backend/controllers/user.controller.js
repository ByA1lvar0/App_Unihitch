const pool = require('../config/db');

const updateUser = async (req, res) => {
    try {
        const { id } = req.params;
        const { nombre, telefono, carrera, contactos_emergencia } = req.body;

        const result = await pool.query(
            'UPDATE usuario SET nombre = $1, telefono = $2, carrera = $3, contactos_emergencia = $4 WHERE id = $5 RETURNING id, nombre, correo, telefono, rol, carrera, contactos_emergencia',
            [nombre, telefono, carrera, contactos_emergencia || null, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al actualizar usuario' });
    }
};

const searchUsers = async (req, res) => {
    try {
        const { query, currentUserId } = req.query;
        if (!query) {
            return res.json([]);
        }

        const result = await pool.query(
            'SELECT id, nombre, correo FROM usuario WHERE (nombre ILIKE $1 OR correo ILIKE $1) AND id != $2 LIMIT 20',
            [`%${query}%`, currentUserId || 0]
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al buscar usuarios' });
    }
};

const updateEmergencyContact = async (req, res) => {
    try {
        const { id } = req.params;
        const { numero_emergencia } = req.body;

        const result = await pool.query(
            'UPDATE usuario SET numero_emergencia = $1 WHERE id = $2 RETURNING id, nombre, numero_emergencia',
            [numero_emergencia, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al actualizar número de emergencia' });
    }
};

const getUser = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            `SELECT u.id, u.nombre, u.correo, u.telefono, u.rol, u.verificado, 
              u.foto_perfil, u.carrera, u.numero_emergencia, u.calificacion_promedio,
              u.id_universidad, u.id_carrera, uni.nombre as universidad_nombre
       FROM usuario u
       LEFT JOIN universidad uni ON u.id_universidad = uni.id
       WHERE u.id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener usuario' });
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

module.exports = { updateUser, searchUsers, updateEmergencyContact, getUser, getUsers };
