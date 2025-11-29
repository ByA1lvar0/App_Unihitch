const express = require('express');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Configuración de PostgreSQL
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

// Middleware
app.use(cors());
app.use(express.json());

// ==================== RUTAS DE AUTENTICACIÓN ====================

// Registro
app.post('/api/register', async (req, res) => {
  try {
    const { nombre, correo, password, telefono, id_universidad } = req.body;

    const userExists = await pool.query('SELECT * FROM usuario WHERE correo = $1', [correo]);
    if (userExists.rows.length > 0) {
      return res.status(400).json({ error: 'Este correo ya está registrado' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await pool.query(
      'INSERT INTO usuario (nombre, correo, password, telefono, id_universidad) VALUES ($1, $2, $3, $4, $5) RETURNING id, nombre, correo, rol',
      [nombre, correo, hashedPassword, telefono, id_universidad]
    );

    const user = result.rows[0];
    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET);

    res.json({ user, token });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al registrar usuario' });
  }
});

// Login
app.post('/api/login', async (req, res) => {
  try {
    const { correo, password } = req.body;

    const result = await pool.query('SELECT * FROM usuario WHERE correo = $1', [correo]);
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Credenciales incorrectas' });
    }

    const user = result.rows[0];

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: 'Credenciales incorrectas' });
    }

    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET);

    res.json({
      user: {
        id: user.id,
        nombre: user.nombre,
        correo: user.correo,
        telefono: user.telefono,
        rol: user.rol,
        carrera: user.carrera
      },
      token
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al iniciar sesión' });
  }
});

// ==================== RUTAS DE UNIVERSIDADES ====================

app.get('/api/universidades', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM universidad ORDER BY nombre');
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al obtener universidades' });
  }
});

// ==================== RUTAS DE VIAJES ====================

// Listar todos los viajes disponibles con filtros
app.get('/api/viajes', async (req, res) => {
  try {
    const { origen, destino, precio_max } = req.query;

    let query = `
      SELECT v.*, 
             u.nombre as conductor_nombre, 
             u.telefono as conductor_telefono, 
             u.carrera, 
             uni.nombre as universidad,
             u.foto_perfil
      FROM viaje v 
      JOIN usuario u ON v.id_conductor = u.id 
      LEFT JOIN universidad uni ON u.id_universidad = uni.id
      WHERE v.estado = 'DISPONIBLE' AND v.fecha_hora > NOW()
    `;

    const params = [];
    let paramCount = 1;

    if (origen) {
      query += ` AND v.origen ILIKE $${paramCount}`;
      params.push(`%${origen}%`);
      paramCount++;
    }

    if (destino) {
      query += ` AND v.destino ILIKE $${paramCount}`;
      params.push(`%${destino}%`);
      paramCount++;
    }

    if (precio_max) {
      query += ` AND v.precio <= $${paramCount}`;
      params.push(precio_max);
      paramCount++;
    }

    query += ` ORDER BY v.fecha_hora`;

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al obtener viajes' });
  }
});

// Crear viaje
app.post('/api/viajes', async (req, res) => {
  try {
    const { id_conductor, origen, destino, fecha_hora, precio, asientos_disponibles } = req.body;

    const result = await pool.query(
      'INSERT INTO viaje (id_conductor, origen, destino, fecha_hora, precio, asientos_disponibles) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [id_conductor, origen, destino, fecha_hora, precio, asientos_disponibles]
    );

    res.json(result.rows[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al crear viaje' });
  }
});

// Mis viajes como conductor
app.get('/api/viajes/conductor/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'SELECT * FROM viaje WHERE id_conductor = $1 ORDER BY fecha_hora DESC',
      [id]
    );
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al obtener viajes' });
  }
});

// ==================== RUTAS DE RESERVAS ====================

// Crear reserva
app.post('/api/reservas', async (req, res) => {
  try {
    const { id_viaje, id_pasajero } = req.body;

    const existingReserva = await pool.query(
      'SELECT * FROM reserva WHERE id_viaje = $1 AND id_pasajero = $2',
      [id_viaje, id_pasajero]
    );

    if (existingReserva.rows.length > 0) {
      return res.status(400).json({ error: 'Ya tienes una reserva para este viaje' });
    }

    const viaje = await pool.query('SELECT asientos_disponibles FROM viaje WHERE id = $1', [id_viaje]);
    if (viaje.rows[0].asientos_disponibles <= 0) {
      return res.status(400).json({ error: 'No hay asientos disponibles' });
    }

    const result = await pool.query(
      'INSERT INTO reserva (id_viaje, id_pasajero) VALUES ($1, $2) RETURNING *',
      [id_viaje, id_pasajero]
    );

    await pool.query(
      'UPDATE viaje SET asientos_disponibles = asientos_disponibles - 1 WHERE id = $1',
      [id_viaje]
    );

    res.json(result.rows[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al crear reserva' });
  }
});

// Mis reservas
app.get('/api/reservas/pasajero/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT r.*, v.origen, v.destino, v.fecha_hora, v.precio, u.nombre as conductor_nombre
      FROM reserva r
      JOIN viaje v ON r.id_viaje = v.id
      JOIN usuario u ON v.id_conductor = u.id
      WHERE r.id_pasajero = $1
      ORDER BY v.fecha_hora DESC
    `, [id]);
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al obtener reservas' });
  }
});

// ==================== RUTAS DE CHAT Y MENSAJES ====================

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
});

// Obtener o crear chat entre dos usuarios
app.post('/api/chats', async (req, res) => {
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
});

// Marcar mensajes como leídos
app.put('/api/chats/:chatId/read/:userId', async (req, res) => {
  try {
    const { chatId, userId } = req.params;
    res.json({ success: true });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al marcar mensajes' });
  }
});

// Contador de mensajes no leídos
app.get('/api/messages/unread-count/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    res.json({ count: 0 });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al obtener contador' });
  }
});

// ==================== RUTAS DE NOTIFICACIONES ====================

// Obtener notificaciones
app.get('/api/notifications/:userId', async (req, res) => {
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

// Marcar notificación como leída
app.put('/api/notifications/:id/read', async (req, res) => {
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
});

// ==================== RUTAS DE USUARIOS ====================

// Actualizar usuario
app.put('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, telefono, carrera } = req.body;

    const result = await pool.query(
      'UPDATE usuario SET nombre = $1, telefono = $2, carrera = $3 WHERE id = $4 RETURNING id, nombre, correo, telefono, rol, carrera',
      [nombre, telefono, carrera, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al actualizar usuario' });
  }
});

// Buscar usuarios
app.get('/api/users/search', async (req, res) => {
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
});

// ==================== RUTAS DE WALLET ====================

// Obtener wallet del usuario
app.get('/api/wallet/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    // Verificar si existe wallet, si no, crear uno
    let wallet = await pool.query('SELECT * FROM wallet WHERE id_usuario = $1', [userId]);

    if (wallet.rows.length === 0) {
      wallet = await pool.query(
        'INSERT INTO wallet (id_usuario, saldo) VALUES ($1, 0.00) RETURNING *',
        [userId]
      );
    }

    // Obtener últimas 10 transacciones
    const transactions = await pool.query(
      'SELECT * FROM transaccion WHERE id_usuario = $1 ORDER BY fecha_transaccion DESC LIMIT 10',
      [userId]
    );

    res.json({
      saldo: wallet.rows[0].saldo,
      transacciones: transactions.rows
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al obtener wallet' });
  }
});

// Recargar saldo
app.post('/api/wallet/recharge', async (req, res) => {
  try {
    const { userId, amount, method } = req.body;

    // Crear transacción
    const transaction = await pool.query(
      'INSERT INTO transaccion (id_usuario, tipo, monto, metodo_pago, descripcion) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [userId, 'RECARGA', amount, method, `Recarga de saldo via ${method}`]
    );

    // Actualizar saldo
    const { userId } = req.params;

    // Obtener viajes completados como conductor
    const conductorTrips = await pool.query(`
      SELECT v.*, COUNT(r.id) as num_pasajeros
      FROM viaje v
      LEFT JOIN reserva r ON v.id = r.id_viaje AND r.estado = 'COMPLETADA'
      WHERE v.id_conductor = $1 AND v.estado = 'COMPLETADO'
      GROUP BY v.id
    `, [userId]);

    // Obtener viajes completados como pasajero
    const pasajeroTrips = await pool.query(`
      SELECT v.*
      FROM viaje v
      JOIN reserva r ON v.id = r.id_viaje
      WHERE r.id_pasajero = $1 AND r.estado = 'COMPLETADA' AND v.estado = 'COMPLETADO'
    `, [userId]);

    let totalCO2Saved = 0;
    let totalKm = 0;
    let totalTrips = 0;

    // Calcular CO2 ahorrado como conductor
    // Fórmula: Por cada pasajero adicional, se ahorra 120g CO2/km
    // (porque ese pasajero no usa su propio auto)
    conductorTrips.rows.forEach(trip => {
      // Estimamos 10km por viaje si no hay distancia
      const distanceKm = trip.distancia_km || 10;
      const passengers = parseInt(trip.num_pasajeros) || 0;

      // CO2 ahorrado = distancia * 0.12 kg/km * número de pasajeros
      const co2Saved = distanceKm * 0.12 * passengers;
      totalCO2Saved += co2Saved;
      totalKm += distanceKm;
      totalTrips++;
    });

    // Calcular CO2 ahorrado como pasajero
    // Como pasajero, ahorras 120g CO2/km al no usar tu propio auto
    pasajeroTrips.rows.forEach(trip => {
      const distanceKm = trip.distancia_km || 10;
      const co2Saved = distanceKm * 0.12;
      totalCO2Saved += co2Saved;
      totalKm += distanceKm;
      totalTrips++;
    });

    res.json({
      totalCO2SavedKg: Math.round(totalCO2Saved * 100) / 100,
      totalKm: totalKm,
      totalTrips: totalTrips,
      equivalentTrees: Math.round((totalCO2Saved / 21) * 10) / 10 // 1 árbol absorbe ~21kg CO2/año
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al obtener estadísticas de CO2' });
  }
});

// ==================== INICIAR SERVIDOR ====================

app.listen(port, () => {
  console.log(`Servidor corriendo en http://localhost:${port}`);
});