const pool = require('../config/db');

const getMessages = async (req, res) => {
    try {
        const { universidadId } = req.params;
        const result = await pool.query(
            `SELECT m.*, u.nombre as nombre_usuario 
       FROM mensaje_comunidad m 
       JOIN usuario u ON m.id_usuario = u.id 
       WHERE m.id_universidad = $1 
       ORDER BY m.fecha_envio ASC`,
            [universidadId]
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener mensajes' });
    }
};

const sendMessage = async (req, res) => {
    try {
        const { userId, universidadId, mensaje } = req.body;

        // Verificar si el usuario está verificado
        const user = await pool.query('SELECT verificado FROM usuario WHERE id = $1', [userId]);
        if (!user.rows[0]) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }
        if (!user.rows[0].verificado) {
            return res.status(403).json({ error: 'Debes estar verificado para enviar mensajes' });
        }

        const result = await pool.query(
            'INSERT INTO mensaje_comunidad (id_usuario, id_universidad, mensaje) VALUES ($1, $2, $3) RETURNING *',
            [userId, universidadId, mensaje]
        );

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al enviar mensaje' });
    }
};

const getMembers = async (req, res) => {
    try {
        const { universidadId } = req.params;
        const result = await pool.query(
            `SELECT u.id, u.nombre, u.correo, u.codigo_universitario, u.verificado, u.rol
       FROM usuario u 
       WHERE u.id_universidad = $1 AND u.verificado = true
       ORDER BY u.nombre`,
            [universidadId]
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener miembros' });
    }
};

module.exports = { getMessages, sendMessage, getMembers };
