// ==================== RUTAS DE CHAT Y MENSAJES ====================
// AGREGAR ESTAS RUTAS AL ARCHIVO server.js ANTES DE "// Iniciar servidor"

// Obtener lista de chats del usuario
app.get('/api/chats/:userId', async (req, res) => {
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
          ELSE c.no_leidos_usuario2
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
});

// Obtener o crear chat entre dos usuarios
app.post('/api/chats', async (req, res) => {
    try {
        const { id_usuario1, id_usuario2 } = req.body;

        // Buscar chat existente
        const existing = await pool.query(`
      SELECT * FROM chat 
      WHERE (id_usuario1 = $1 AND id_usuario2 = $2) 
         OR (id_usuario1 = $2 AND id_usuario2 = $1)
    `, [id_usuario1, id_usuario2]);

        if (existing.rows.length > 0) {
            return res.json(existing.rows[0]);
        }

        // Crear nuevo chat
        const result = await pool.query(
            'INSERT INTO chat (id_usuario1, id_usuario2) VALUES ($1, $2) RETURNING *',
            [id_usuario1, id_usuario2]
        );
        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al crear chat' });
    }
});

// Obtener mensajes de un chat
app.get('/api/chats/:chatId/messages', async (req, res) => {
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
});

// Enviar mensaje
app.post('/api/messages', async (req, res) => {
    try {
        const { id_chat, id_remitente, mensaje } = req.body;

        // Insertar mensaje
        const result = await pool.query(
            'INSERT INTO mensaje (id_chat, id_remitente, mensaje) VALUES ($1, $2, $3) RETURNING *',
            [id_chat, id_remitente, mensaje]
        );

        // Obtener info del chat para actualizar
        const chat = await pool.query('SELECT * FROM chat WHERE id = $1', [id_chat]);
        const chatData = chat.rows[0];

        // Actualizar último mensaje y contador de no leídos
        if (chatData.id_usuario1 === parseInt(id_remitente)) {
            await pool.query(`
        UPDATE chat 
        SET ultimo_mensaje = $1, 
            fecha_ultimo_mensaje = NOW(),
            no_leidos_usuario2 = no_leidos_usuario2 + 1
        WHERE id = $2
      `, [mensaje, id_chat]);
        } else {
            await pool.query(`
        UPDATE chat 
        SET ultimo_mensaje = $1, 
            fecha_ultimo_mensaje = NOW(),
            no_leidos_usuario1 = no_leidos_usuario1 + 1
        WHERE id = $2
      `, [mensaje, id_chat]);
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al enviar mensaje' });
    }
});

// Marcar mensajes como leídos
app.put('/api/chats/:chatId/read/:userId', async (req, res) => {
    try {
        const { chatId, userId } = req.params;

        // Marcar mensajes como leídos
        await pool.query(`
      UPDATE mensaje 
      SET leido = TRUE 
      WHERE id_chat = $1 AND id_remitente != $2 AND leido = FALSE
    `, [chatId, userId]);

        // Resetear contador de no leídos
        const chat = await pool.query('SELECT * FROM chat WHERE id = $1', [chatId]);
        const chatData = chat.rows[0];

        if (chatData.id_usuario1 === parseInt(userId)) {
            await pool.query('UPDATE chat SET no_leidos_usuario1 = 0 WHERE id = $1', [chatId]);
        } else {
            await pool.query('UPDATE chat SET no_leidos_usuario2 = 0 WHERE id = $1', [chatId]);
        }

        res.json({ success: true });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al marcar mensajes como leídos' });
    }
});

// Obtener contador total de mensajes no leídos
app.get('/api/messages/unread-count/:userId', async (req, res) => {
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
        res.json({ count: parseInt(result.rows[0].total_no_leidos) });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener contador' });
    }
});

// ==================== RUTAS DE NOTIFICACIONES ====================

// Obtener notificaciones del usuario
app.get('/api/notifications/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const result = await pool.query(`
      SELECT * FROM notificacion 
      WHERE id_usuario = $1 
      ORDER BY fecha_creacion DESC
      LIMIT 50
    `, [userId]);
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener notificaciones' });
    }
});

// Obtener contador de notificaciones no leídas
app.get('/api/notifications/:userId/unread-count', async (req, res) => {
    try {
        const { userId } = req.params;
        const result = await pool.query(
            'SELECT COUNT(*) as count FROM notificacion WHERE id_usuario = $1 AND leida = FALSE',
            [userId]
        );
        res.json({ count: parseInt(result.rows[0].count) });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener contador' });
    }
});

// Marcar notificación como leída
app.put('/api/notifications/:notificationId/read', async (req, res) => {
    try {
        const { notificationId } = req.params;
        await pool.query(
            'UPDATE notificacion SET leida = TRUE WHERE id = $1',
            [notificationId]
        );
        res.json({ success: true });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al marcar notificación' });
    }
});

// Crear notificación
app.post('/api/notifications', async (req, res) => {
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
});
