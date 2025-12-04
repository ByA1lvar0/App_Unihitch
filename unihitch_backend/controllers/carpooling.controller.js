const pool = require('../config/db');

// Get all groups (with filters)
const getGroups = async (req, res) => {
    try {
        const { tipo_grupo, estado } = req.query;

        let query = `
      SELECT g.*, 
        u.nombre as organizador_nombre,
        COUNT(m.id) as miembros_actuales
      FROM grupos_viaje g
      JOIN usuario u ON g.id_organizador = u.id
      LEFT JOIN miembros_grupo m ON g.id = m.id_grupo AND m.estado = 'ACTIVO'
      WHERE 1=1
    `;

        const params = [];
        let paramCount = 1;

        if (tipo_grupo) {
            query += ` AND g.tipo_grupo = $${paramCount}`;
            params.push(tipo_grupo);
            paramCount++;
        }

        if (estado) {
            query += ` AND g.estado = $${paramCount}`;
            params.push(estado);
            paramCount++;
        } else {
            query += ` AND g.estado = 'ABIERTO'`;
        }

        query += ` GROUP BY g.id, u.nombre ORDER BY g.fecha_creacion DESC`;

        const result = await pool.query(query, params);
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener grupos' });
    }
};

// Create group
const createGroup = async (req, res) => {
    try {
        const {
            id_organizador,
            ruta_comun,
            origen,
            destino,
            horario_preferido,
            dias_semana,
            tipo_grupo,
            costo_total,
            num_pasajeros,
            descripcion
        } = req.body;

        const costo_por_persona = costo_total && num_pasajeros ? (costo_total / num_pasajeros).toFixed(2) : null;

        const result = await pool.query(
            `INSERT INTO grupos_viaje 
       (id_organizador, ruta_comun, origen, destino, horario_preferido, dias_semana, tipo_grupo, costo_total, num_pasajeros, costo_por_persona, descripcion)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING *`,
            [id_organizador, ruta_comun, origen, destino, horario_preferido, dias_semana, tipo_grupo, costo_total, num_pasajeros, costo_por_persona, descripcion]
        );

        // Add organizer as first member
        await pool.query(
            'INSERT INTO miembros_grupo (id_grupo, id_usuario) VALUES ($1, $2)',
            [result.rows[0].id, id_organizador]
        );

        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al crear grupo' });
    }
};

// Get group details
const getGroupDetails = async (req, res) => {
    try {
        const { id } = req.params;

        const groupResult = await pool.query(
            `SELECT g.*, u.nombre as organizador_nombre, u.telefono as organizador_telefono
       FROM grupos_viaje g
       JOIN usuario u ON g.id_organizador = u.id
       WHERE g.id = $1`,
            [id]
        );

        if (groupResult.rows.length === 0) {
            return res.status(404).json({ error: 'Grupo no encontrado' });
        }

        const membersResult = await pool.query(
            `SELECT m.*, u.nombre, u.telefono
       FROM miembros_grupo m
       JOIN usuario u ON m.id_usuario = u.id
       WHERE m.id_grupo = $1 AND m.estado = 'ACTIVO'
       ORDER BY m.fecha_union`,
            [id]
        );

        res.json({
            ...groupResult.rows[0],
            miembros: membersResult.rows
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener detalles del grupo' });
    }
};

// Join group
const joinGroup = async (req, res) => {
    try {
        const { id } = req.params;
        const { id_usuario } = req.body;

        // Check if group is full
        const groupCheck = await pool.query(
            `SELECT g.num_pasajeros, COUNT(m.id) as miembros_actuales
       FROM grupos_viaje g
       LEFT JOIN miembros_grupo m ON g.id = m.id_grupo AND m.estado = 'ACTIVO'
       WHERE g.id = $1 AND g.estado = 'ABIERTO'
       GROUP BY g.id, g.num_pasajeros`,
            [id]
        );

        if (groupCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Grupo no encontrado o cerrado' });
        }

        const { num_pasajeros, miembros_actuales } = groupCheck.rows[0];

        if (parseInt(miembros_actuales) >= num_pasajeros) {
            return res.status(400).json({ error: 'Grupo completo' });
        }

        // Add member
        const result = await pool.query(
            'INSERT INTO miembros_grupo (id_grupo, id_usuario) VALUES ($1, $2) ON CONFLICT (id_grupo, id_usuario) DO UPDATE SET estado = \'ACTIVO\' RETURNING *',
            [id, id_usuario]
        );

        // Check if group is now full
        if (parseInt(miembros_actuales) + 1 >= num_pasajeros) {
            await pool.query(
                'UPDATE grupos_viaje SET estado = \'COMPLETO\' WHERE id = $1',
                [id]
            );
        }

        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al unirse al grupo' });
    }
};

// Leave group
const leaveGroup = async (req, res) => {
    try {
        const { id } = req.params;
        const { id_usuario } = req.body;

        await pool.query(
            'UPDATE miembros_grupo SET estado = \'INACTIVO\' WHERE id_grupo = $1 AND id_usuario = $2',
            [id, id_usuario]
        );

        // Reopen group if it was full
        await pool.query(
            'UPDATE grupos_viaje SET estado = \'ABIERTO\' WHERE id = $1 AND estado = \'COMPLETO\'',
            [id]
        );

        res.json({ message: 'Has salido del grupo' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al salir del grupo' });
    }
};

// Get user's groups
const getMyGroups = async (req, res) => {
    try {
        const { userId } = req.params;

        const result = await pool.query(
            `SELECT g.*, u.nombre as organizador_nombre,
        COUNT(m.id) as miembros_actuales
       FROM grupos_viaje g
       JOIN usuario u ON g.id_organizador = u.id
       JOIN miembros_grupo m2 ON g.id = m2.id_grupo
       LEFT JOIN miembros_grupo m ON g.id = m.id_grupo AND m.estado = 'ACTIVO'
       WHERE m2.id_usuario = $1 AND m2.estado = 'ACTIVO'
       GROUP BY g.id, u.nombre
       ORDER BY g.fecha_creacion DESC`,
            [userId]
        );

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener tus grupos' });
    }
};

module.exports = {
    getGroups,
    createGroup,
    getGroupDetails,
    joinGroup,
    leaveGroup,
    getMyGroups
};
