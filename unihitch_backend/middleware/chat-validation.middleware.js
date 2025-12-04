const pool = require('../config/db');

/**
 * Middleware para validar que el usuario puede crear un chat
 * Agentes externos solo pueden chatear sobre viajes donde son conductores
 */
const validateChatAccess = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const { id_usuario1, id_usuario2, id_viaje, id_reserva } = req.body;

        // Obtener información del usuario
        const userResult = await pool.query(
            'SELECT es_agente_externo, id_universidad FROM usuario WHERE id = $1',
            [userId]
        );

        if (userResult.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        const user = userResult.rows[0];

        // Si es agente externo, SOLO puede chatear sobre viajes donde participa
        if (user.es_agente_externo) {
            if (!id_viaje && !id_reserva) {
                return res.status(403).json({
                    error: 'Los agentes externos solo pueden chatear sobre viajes activos',
                    detalle: 'Debes tener un viaje activo con el pasajero para poder chatear'
                });
            }

            // Verificar que sea conductor del viaje
            if (id_viaje) {
                const viajeResult = await pool.query(
                    'SELECT id_conductor FROM viaje WHERE id = $1',
                    [id_viaje]
                );

                if (viajeResult.rows.length === 0) {
                    return res.status(404).json({ error: 'Viaje no encontrado' });
                }

                if (viajeResult.rows[0].id_conductor !== userId) {
                    return res.status(403).json({
                        error: 'Solo puedes chatear sobre viajes que tú conduces'
                    });
                }

                // Verificar que el otro usuario sea pasajero del viaje
                const otroUsuarioId = id_usuario1 === userId ? id_usuario2 : id_usuario1;
                const reservaResult = await pool.query(
                    'SELECT * FROM reserva WHERE id_viaje = $1 AND id_pasajero = $2 AND estado != $3',
                    [id_viaje, otroUsuarioId, 'CANCELADA']
                );

                if (reservaResult.rows.length === 0) {
                    return res.status(403).json({
                        error: 'Solo puedes chatear con pasajeros que tienen reserva en tu viaje',
                        detalle: 'El usuario debe tener una reserva activa en tu viaje'
                    });
                }
            }
        }

        // Universitarios pueden chatear libremente entre ellos
        next();
    } catch (error) {
        console.error('Error validando acceso a chat:', error);
        res.status(500).json({ error: 'Error validando acceso a chat' });
    }
};

/**
 * Middleware para validar que el usuario puede enviar mensajes en un chat
 */
const validateMessageAccess = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const { id_chat } = req.body;

        // Verificar que el usuario sea parte del chat
        const chatResult = await pool.query(
            'SELECT * FROM chat WHERE id = $1 AND (id_usuario1 = $2 OR id_usuario2 = $2)',
            [id_chat, userId]
        );

        if (chatResult.rows.length === 0) {
            return res.status(403).json({
                error: 'No tienes acceso a este chat'
            });
        }

        const chat = chatResult.rows[0];

        // Si es agente externo, verificar que el viaje siga activo
        const userResult = await pool.query(
            'SELECT es_agente_externo FROM usuario WHERE id = $1',
            [userId]
        );

        if (userResult.rows[0].es_agente_externo && chat.id_viaje) {
            const viajeResult = await pool.query(
                'SELECT estado FROM viaje WHERE id = $1',
                [chat.id_viaje]
            );

            if (viajeResult.rows.length === 0) {
                return res.status(403).json({
                    error: 'El viaje asociado a este chat ya no existe'
                });
            }

            const estado = viajeResult.rows[0].estado;
            if (estado === 'CANCELADO') {
                return res.status(403).json({
                    error: 'No puedes enviar mensajes en un viaje cancelado'
                });
            }
        }

        next();
    } catch (error) {
        console.error('Error validando acceso a mensaje:', error);
        res.status(500).json({ error: 'Error validando acceso a mensaje' });
    }
};

module.exports = { validateChatAccess, validateMessageAccess };
