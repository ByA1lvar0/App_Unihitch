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

    // Verificar si el usuario ya existe
    const userExists = await pool.query('SELECT * FROM usuario WHERE correo = $1', [correo]);
    if (userExists.rows.length > 0) {
      return res.status(400).json({ error: 'Este correo ya está registrado' });
    }

    // Encriptar contraseña
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insertar usuario
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

    // Buscar usuario
    const result = await pool.query('SELECT * FROM usuario WHERE correo = $1', [correo]);
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Credenciales incorrectas' });
    }

    const user = result.rows[0];

    // Verificar contraseña
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
        rol: user.rol
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

// Listar todos los viajes disponibles
app.get('/api/viajes', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT v.*, u.nombre as conductor_nombre, u.telefono as conductor_telefono 
      FROM viaje v 
      JOIN usuario u ON v.id_conductor = u.id 
      WHERE v.estado = 'DISPONIBLE' AND v.fecha_hora > NOW()
      ORDER BY v.fecha_hora
    `);
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

    // Verificar si ya tiene una reserva
    const existingReserva = await pool.query(
      'SELECT * FROM reserva WHERE id_viaje = $1 AND id_pasajero = $2',
      [id_viaje, id_pasajero]
    );

    if (existingReserva.rows.length > 0) {
      return res.status(400).json({ error: 'Ya tienes una reserva para este viaje' });
    }

    // Verificar asientos disponibles
    const viaje = await pool.query('SELECT asientos_disponibles FROM viaje WHERE id = $1', [id_viaje]);
    if (viaje.rows[0].asientos_disponibles <= 0) {
      return res.status(400).json({ error: 'No hay asientos disponibles' });
    }

    // Crear reserva
    const result = await pool.query(
      'INSERT INTO reserva (id_viaje, id_pasajero) VALUES ($1, $2) RETURNING *',
      [id_viaje, id_pasajero]
    );

    // Reducir asientos disponibles
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

// Iniciar servidor
app.listen(port, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${port}`);
});