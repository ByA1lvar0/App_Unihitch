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
        END as mensajes_no_leidos
      FROM chat c
      JOIN usuario u1 ON c.id_usuario1 = u1.id
      JOIN usuario u2 ON c.id_usuario2 = u2.id
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
        const { id_usuario1, id_usuario2 } = req.body;

        const existing = await pool.query(`
      SELECT * FROM chat 
      WHERE (id_usuario1 = $1 AND id_usuario2 = $2) 
         OR (id_usuario1 = $2 AND id_usuario2 = $1)
    `, [id_usuario1, id_usuario2]);

        if (existing.rows.length > 0) {
            return res.json(existing.rows[0]);
        }

        const result = await pool.query(
            'INSERT INTO chat (id_usuario1, id_usuario2) VALUES ($1, $2) RETURNING *',
            [id_usuario1, id_usuario2]
        );
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al crear chat' });
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

        const result = await pool.query(
            'INSERT INTO mensaje (id_chat, id_remitente, mensaje) VALUES ($1, $2, $3) RETURNING *',
            [id_chat, id_remitente, mensaje]
        );

        await pool.query(
            'UPDATE chat SET ultimo_mensaje = $1, fecha_ultimo_mensaje = NOW() WHERE id = $2',
            [mensaje, id_chat]
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
        // TODO: Implement logic to update read status in DB if needed (currently returns success)
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
