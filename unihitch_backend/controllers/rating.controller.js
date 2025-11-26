const pool = require('../config/db');

const submitRating = async (req, res) => {
    const client = await pool.connect();
    try {
        const { id_viaje, id_autor, id_destinatario, puntuacion, comentario } = req.body;

        // Verificar que el viaje existe y que el autor y destinatario participaron
        // (Simplificado: solo verificamos que no se califiquen a sí mismos)
        if (id_autor === id_destinatario) {
            return res.status(400).json({ error: 'No puedes calificarte a ti mismo' });
        }

        await client.query('BEGIN');

        // Insertar calificación
        const result = await client.query(
            'INSERT INTO calificacion (id_viaje, id_autor, id_destinatario, puntuacion, comentario) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [id_viaje, id_autor, id_destinatario, puntuacion, comentario]
        );

        // Recalcular promedio del destinatario
        const avgResult = await client.query(
            'SELECT AVG(puntuacion) as promedio FROM calificacion WHERE id_destinatario = $1',
            [id_destinatario]
        );

        const nuevoPromedio = parseFloat(avgResult.rows[0].promedio).toFixed(2);

        // Actualizar usuario
        await client.query(
            'UPDATE usuario SET calificacion_promedio = $1 WHERE id = $2',
            [nuevoPromedio, id_destinatario]
        );

        await client.query('COMMIT');

        res.json({
            mensaje: 'Calificación enviada exitosamente',
            calificacion: result.rows[0],
            nuevo_promedio: nuevoPromedio
        });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error(error);
        res.status(500).json({ error: 'Error al enviar calificación' });
    } finally {
        client.release();
    }
};

const getRatings = async (req, res) => {
    try {
        const { userId } = req.params;
        const result = await pool.query(
            `SELECT c.*, u.nombre as autor_nombre, u.foto_perfil as autor_foto
       FROM calificacion c
       JOIN usuario u ON c.id_autor = u.id
       WHERE c.id_destinatario = $1
       ORDER BY c.fecha DESC`,
            [userId]
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener calificaciones' });
    }
};

module.exports = { submitRating, getRatings };
