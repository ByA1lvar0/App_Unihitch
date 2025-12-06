const pool = require('../config/db');

const getChats = async (req, res) => {
    try {
        const { userId } = req.params;
        const result = await pool.query(`
      SELECT 
        c.*,
        CASE 
          WHEN c.id_usuario1 = $1 THEN u2.nombre
          ELSE u1.nombre
        END as otro_usuario_nombre,
        CASE 
          WHEN c.id_usuario1 = $1 THEN c.id_usuario2
          ELSE c.id_usuario1
        END as otro_usuario_id,
        CASE 
          WHEN c.id_usuario1 = $1 THEN c.no_leidos_usuario1
          WHEN c.id_usuario2 = $1 THEN c.no_leidos_usuario2
        END as mensajes_no_leidos,
        CASE 
          WHEN c.id_usuario1 = $1 THEN uni2.nombre
          ELSE uni1.nombre
        END as otro_usuario_universidad,
        v.origen as viaje_origen,
        v.destino as viaje_destino,
        v.estado as viaje_estado,
        v.fecha_hora as viaje_fecha
      FROM chat c
      JOIN usuario u1 ON c.id_usuario1 = u1.id
      JOIN usuario u2 ON c.id_usuario2 = u2.id
      LEFT JOIN universidad uni1 ON u1.id_universidad = uni1.id
      LEFT JOIN universidad uni2 ON u2.id_universidad = uni2.id
      LEFT JOIN viaje v ON c.id_viaje = v.id
      WHERE c.id_usuario1 = $1 OR c.id_usuario2 = $1
      ORDER BY c.fecha_ultimo_mensaje DESC NULLS LAST
    `, [userId]);
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener chats' });
    }
};

const getUnreadCount = async (req, res) => {
    try {
        const { userId } = req.params;
        const result = await pool.query(`
      SELECT 
        COALESCE(SUM(
          CASE 
            WHEN id_usuario1 = $1 THEN no_leidos_usuario1
            WHEN id_usuario2 = $1 THEN no_leidos_usuario2
            ELSE 0
          END
        ), 0) as total_no_leidos
      FROM chat
      WHERE id_usuario1 = $1 OR id_usuario2 = $1
    `, [userId]);

        res.json({
            unreadCount: parseInt(result.rows[0].total_no_leidos) || 0
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener contador de mensajes' });
    }
};

const createChat = async (req, res) => {
    try {
        const { id_usuario1, id_usuario2, id_viaje, id_reserva, tipo_chat } = req.body;

        // Verificar si alguno de los usuarios tiene bloqueado al otro (si la tabla existe)
        try {
            const blockCheck = await pool.query(
                `SELECT EXISTS(
                    SELECT 1 FROM usuario_bloqueado 
                    WHERE (id_usuario = $1 AND id_usuario_bloqueado = $2)
                       OR (id_usuario = $2 AND id_usuario_bloqueado = $1)
                ) as bloqueado`,
                [id_usuario1, id_usuario2]
            );

            if (blockCheck.rows[0].bloqueado) {
                return res.status(403).json({
                    error: 'No puedes iniciar un chat con este usuario',
                    detalle: 'Uno de los usuarios ha bloqueado al otro'
                });
            }
        } catch (blockError) {
            // Si la tabla usuario_bloqueado no existe, continuar sin verificar bloqueos
            console.log('Tabla usuario_bloqueado no existe, omitiendo verificación de bloqueos');
        }

        // Verificar si ya existe un chat entre estos usuarios para este viaje
        let query = `
            SELECT * FROM chat 
            WHERE ((id_usuario1 = $1 AND id_usuario2 = $2) 
               OR (id_usuario1 = $2 AND id_usuario2 = $1))
        `;
        const params = [id_usuario1, id_usuario2];

        if (id_viaje) {
            query += ' AND id_viaje = $3';
            params.push(id_viaje);
        }

        const existing = await pool.query(query, params);

        if (existing.rows.length > 0) {
            return res.json(existing.rows[0]);
        }

        // Determinar tipo de chat por defecto
        let finalTipoChat = tipo_chat;
        if (!finalTipoChat) {
            finalTipoChat = id_viaje ? 'VIAJE' : 'COMUNIDAD';
        }

        // Crear nuevo chat con contexto
        const result = await pool.query(
            `INSERT INTO chat (id_usuario1, id_usuario2, id_viaje, id_reserva, tipo_chat) 
             VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            [id_usuario1, id_usuario2, id_viaje || null, id_reserva || null, finalTipoChat]
        );

        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error al crear chat:', error);
        res.status(500).json({ error: 'Error al crear chat', details: error.message });
    }
};

const getMessages = async (req, res) => {
    try {
        const { chatId } = req.params;
        const result = await pool.query(`
      SELECT m.*, u.nombre as remitente_nombre
      FROM mensaje m
      JOIN usuario u ON m.id_remitente = u.id
      WHERE m.id_chat = $1
      ORDER BY m.fecha_envio ASC
    `, [chatId]);
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener mensajes' });
    }
};

const sendMessage = async (req, res) => {
    try {
        const { id_chat, id_remitente, mensaje } = req.body;

        // Obtener información del chat y verificar bloqueo
        const chatInfo = await pool.query(
            'SELECT id_usuario1, id_usuario2 FROM chat WHERE id = $1',
            [id_chat]
        );

        if (chatInfo.rows.length === 0) {
            return res.status(404).json({ error: 'Chat no encontrado' });
        }

        const { id_usuario1, id_usuario2 } = chatInfo.rows[0];
        const id_destinatario = id_usuario1 === id_remitente ? id_usuario2 : id_usuario1;

        // Verificar si hay bloqueo (si la tabla existe)
        try {
            const blockCheck = await pool.query(
                `SELECT EXISTS(
                    SELECT 1 FROM usuario_bloqueado 
                    WHERE (id_usuario = $1 AND id_usuario_bloqueado = $2)
                       OR (id_usuario = $2 AND id_usuario_bloqueado = $1)
                ) as bloqueado`,
                [id_remitente, id_destinatario]
            );

            if (blockCheck.rows[0].bloqueado) {
                return res.status(403).json({
                    error: 'No puedes enviar mensajes a este usuario',
                    detalle: 'Uno de los usuarios ha bloqueado al otro'
                });
            }
        } catch (blockError) {
            // Si la tabla usuario_bloqueado no existe, continuar sin verificar bloqueos
            console.log('Tabla usuario_bloqueado no existe, omitiendo verificación de bloqueos en sendMessage');
        }

        // Insertar mensaje
        const result = await pool.query(
            'INSERT INTO mensaje (id_chat, id_remitente, mensaje) VALUES ($1, $2, $3) RETURNING *',
            [id_chat, id_remitente, mensaje]
        );

        // Actualizar último mensaje del chat
        await pool.query(
            'UPDATE chat SET ultimo_mensaje = $1, fecha_ultimo_mensaje = NOW() WHERE id = $2',
            [mensaje, id_chat]
        );

        // Incrementar contador de no leídos para el destinatario
        const counterField = id_destinatario === id_usuario1 ? 'no_leidos_usuario1' : 'no_leidos_usuario2';
        await pool.query(
            `UPDATE chat SET ${counterField} = ${counterField} + 1 WHERE id = $1`,
            [id_chat]
        );

        // Obtener nombre del remitente para la notificación
        const senderInfo = await pool.query(
            'SELECT nombre FROM usuario WHERE id = $1',
            [id_remitente]
        );

        const senderName = senderInfo.rows[0]?.nombre || 'Un usuario';

        // Crear notificación para el destinatario
        await pool.query(
            `INSERT INTO notificacion (id_usuario, titulo, mensaje, tipo) 
             VALUES ($1, $2, $3, $4)`,
            [
                id_destinatario,
                `Nuevo mensaje de ${senderName}`,
                mensaje.length > 50 ? mensaje.substring(0, 50) + '...' : mensaje,
                'MENSAJE'
            ]
        );

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al enviar mensaje' });
    }
};

const markAsRead = async (req, res) => {
    try {
        const { chatId, userId } = req.params;

        // Obtener información del chat para saber qué contador resetear
        const chatInfo = await pool.query(
            'SELECT id_usuario1, id_usuario2 FROM chat WHERE id = $1',
            [chatId]
        );

        if (chatInfo.rows.length === 0) {
            return res.status(404).json({ error: 'Chat no encontrado' });
        }

        const { id_usuario1, id_usuario2 } = chatInfo.rows[0];
        const userIdInt = parseInt(userId);

        // Determinar qué campo resetear
        const counterField = userIdInt === id_usuario1 ? 'no_leidos_usuario1' : 'no_leidos_usuario2';

        // Resetear contador de no leídos
        await pool.query(
            `UPDATE chat SET ${counterField} = 0 WHERE id = $1`,
            [chatId]
        );

        res.json({ success: true });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al marcar mensajes' });
    }
};

const getUnreadMessagesCount = async (req, res) => {
    try {
        const { userId } = req.params;
        res.json({ count: 0 }); // Placeholder as in original code
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener contador' });
    }
};

module.exports = {
    getChats,
    getUnreadCount,
    createChat,
    getMessages,
    sendMessage,
    markAsRead,
    getUnreadMessagesCount
};
