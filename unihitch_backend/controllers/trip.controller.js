const pool = require('../config/db');

const getTrips = async (req, res) => {
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
};

const createTrip = async (req, res) => {
    try {
        const { id_conductor, origen, destino, fecha_hora, precio, asientos_disponibles, acepta_efectivo } = req.body;

        // Verificar documentos del conductor
        const userResult = await pool.query(
            'SELECT tipo_usuario, es_agente_externo FROM usuario WHERE id = $1',
            [id_conductor]
        );

        if (userResult.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        const user = userResult.rows[0];
        const esAgenteExterno = user.es_agente_externo || false;

        // Obtener documentos aprobados del conductor
        const docsResult = await pool.query(
            `SELECT tipo_documento FROM documentos_conductor 
       WHERE id_conductor = $1 AND estado = 'APROBADO'`,
            [id_conductor]
        );

        const docsAprobados = docsResult.rows.map(row => row.tipo_documento);

        // Documentos requeridos según tipo de usuario
        // Todos los conductores (universitarios y externos) requieren los mismos documentos básicos
        let documentosRequeridos = ['SOAT', 'LICENCIA', 'FOTO_PERFIL', 'TARJETA_PROPIEDAD'];

        // Verificar que tiene todos los documentos requeridos
        const documentosFaltantes = documentosRequeridos.filter(doc => !docsAprobados.includes(doc));

        if (documentosFaltantes.length > 0) {
            return res.status(403).json({
                error: 'Debes tener todos los documentos aprobados para ofrecer viajes',
                documentos_faltantes: documentosFaltantes,
                mensaje: 'Requieres: Foto de Perfil, SOAT, Licencia de Conducir y Tarjeta de Propiedad aprobados'
            });
        }

        // Crear el viaje
        const insertQuery = acepta_efectivo !== undefined
            ? 'INSERT INTO viaje (id_conductor, origen, destino, fecha_hora, precio, asientos_disponibles, asientos_totales, acepta_efectivo) VALUES ($1, $2, $3, $4, $5, $6, $6, $7) RETURNING *'
            : 'INSERT INTO viaje (id_conductor, origen, destino, fecha_hora, precio, asientos_disponibles, asientos_totales) VALUES ($1, $2, $3, $4, $5, $6, $6) RETURNING *';

        const insertParams = acepta_efectivo !== undefined
            ? [id_conductor, origen, destino, fecha_hora, precio, asientos_disponibles, acepta_efectivo]
            : [id_conductor, origen, destino, fecha_hora, precio, asientos_disponibles];

        const result = await pool.query(insertQuery, insertParams);

        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error al crear viaje:', error);
        res.status(500).json({ error: 'Error al crear viaje', details: error.message });
    }
};

const getDriverTrips = async (req, res) => {
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
};

const searchTrips = async (req, res) => {
    try {
        const { query, sortBy = 'fecha_hora' } = req.query;

        let viajesQuery = `
      SELECT v.*, 
             u.nombre as conductor_nombre, 
             u.telefono as conductor_telefono, 
             u.carrera, 
             uni.nombre as universidad,
             u.foto_perfil,
             u.calificacion_promedio
      FROM viaje v 
      JOIN usuario u ON v.id_conductor = u.id 
      LEFT JOIN universidad uni ON u.id_universidad = uni.id
      WHERE v.estado = 'DISPONIBLE' AND v.fecha_hora > NOW()
    `;

        const params = [];

        if (query) {
            viajesQuery += ` AND (v.destino ILIKE $1 OR v.origen ILIKE $1)`;
            params.push(`%${query}%`);
        }

        // Ordenamiento dinámico
        switch (sortBy) {
            case 'precio':
                viajesQuery += ` ORDER BY v.precio ASC`;
                break;
            case 'calificacion':
                viajesQuery += ` ORDER BY u.calificacion_promedio DESC`;
                break;
            case 'asientos':
                viajesQuery += ` ORDER BY v.asientos_disponibles DESC`;
                break;
            default:
                viajesQuery += ` ORDER BY v.fecha_hora ASC`;
        }

        const viajes = await pool.query(viajesQuery, params);

        // Obtener destinos populares
        const destinosPopulares = await pool.query(`
      SELECT destino, COUNT(*) as frecuencia
      FROM viaje
      WHERE estado = 'DISPONIBLE' AND fecha_hora > NOW()
      GROUP BY destino
      ORDER BY frecuencia DESC
      LIMIT 5
    `);

        // Obtener sugerencias
        let sugerencias = [];
        if (query && query.length >= 2) {
            const sugerenciasResult = await pool.query(`
        SELECT DISTINCT destino
        FROM viaje
        WHERE destino ILIKE $1 AND estado = 'DISPONIBLE' AND fecha_hora > NOW()
        LIMIT 5
      `, [`%${query}%`]);
            sugerencias = sugerenciasResult.rows.map(r => r.destino);
        }

        res.json({
            viajes: viajes.rows,
            destinos_populares: destinosPopulares.rows.map(d => d.destino),
            sugerencias: sugerencias,
            total: viajes.rows.length
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al buscar viajes' });
    }
};

const updateLocation = async (req, res) => {
    try {
        const { id } = req.params; // Trip ID
        const { userId, latitud, longitud } = req.body;

        console.log('Update Location Request:', { tripId: id, body: req.body });

        if (!userId || !latitud || !longitud) {
            console.error('Missing parameters in updateLocation');
            return res.status(400).json({ error: 'Faltan parámetros (userId, latitud, longitud)' });
        }

        const userIdInt = parseInt(userId, 10);
        if (isNaN(userIdInt)) {
            console.error('Invalid userId:', userId);
            return res.status(400).json({ error: 'ID de usuario inválido' });
        }

        // Verificar si el usuario es conductor o pasajero del viaje
        const trip = await pool.query(
            'SELECT id_conductor FROM viaje WHERE id = $1',
            [id]
        );

        if (trip.rows.length === 0) {
            return res.status(404).json({ error: 'Viaje no encontrado' });
        }

        const isDriver = trip.rows[0].id_conductor === userIdInt;
        const role = isDriver ? 'conductor' : 'pasajero';

        console.log(`User ${userIdInt} determined as ${role} for trip ${id}`);

        // Upsert ubicación (Insert or Update)
        await pool.query(
            `INSERT INTO ubicacion_viaje (id_viaje, id_usuario, latitud, longitud, rol, fecha_actualizacion)
             VALUES ($1, $2, $3, $4, $5, NOW())
             ON CONFLICT (id_viaje, id_usuario) 
             DO UPDATE SET latitud = EXCLUDED.latitud, longitud = EXCLUDED.longitud, fecha_actualizacion = NOW()`,
            [id, userIdInt, latitud, longitud, role]
        );

        res.json({ success: true });
    } catch (error) {
        console.error('Error updating location:', error);
        res.status(500).json({ error: 'Error al actualizar ubicación', details: error.message });
    }
};

const getTripLocations = async (req, res) => {
    try {
        const { id } = req.params; // Trip ID

        // 1. Obtener el Conductor del viaje y su última ubicación
        const driverQuery = await pool.query(`
            SELECT 
                u.id as id_usuario, u.nombre, u.foto_perfil, u.telefono,
                uv.latitud, uv.longitud, uv.fecha_actualizacion,
                'conductor' as rol
            FROM viaje v
            JOIN usuario u ON v.id_conductor = u.id
            LEFT JOIN ubicacion_viaje uv ON uv.id_viaje = v.id AND uv.id_usuario = u.id
            WHERE v.id = $1
        `, [id]);

        // 2. Obtener Pasajeros con reserva (APROBADA/COMPLETADA) y su última ubicación
        const passengersQuery = await pool.query(`
            SELECT 
                u.id as id_usuario, u.nombre, u.foto_perfil, u.telefono,
                uv.latitud, uv.longitud, uv.fecha_actualizacion,
                'pasajero' as rol
            FROM reserva r
            JOIN usuario u ON r.id_pasajero = u.id
            LEFT JOIN ubicacion_viaje uv ON uv.id_viaje = r.id_viaje AND uv.id_usuario = u.id
            WHERE r.id_viaje = $1 AND r.estado IN ('APROBADA', 'COMPLETADA', 'PENDIENTE', 'CONFIRMADA')
        `, [id]);

        const conductor = driverQuery.rows[0];
        // Si no hay ubicación reciente (o nunca hubo), latitud/longitud serán null, el frontend lo maneja.

        res.json({
            conductor: conductor || null,
            pasajeros: passengersQuery.rows
        });
    } catch (error) {
        console.error('Error getting locations:', error);
        res.status(500).json({ error: 'Error al obtener ubicaciones' });
    }
};

module.exports = { getTrips, createTrip, getDriverTrips, searchTrips, updateLocation, getTripLocations };
