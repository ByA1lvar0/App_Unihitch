// Endpoint de búsqueda mejorada de viajes (estilo Uber)
// Agregar este código en server.js después del endpoint de viajes del conductor

app.get('/api/viajes/search', async (req, res) => {
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

        // Obtener destinos populares (los 5 más frecuentes)
        const destinosPopulares = await pool.query(`
      SELECT destino, COUNT(*) as frecuencia
      FROM viaje
      WHERE estado = 'DISPONIBLE' AND fecha_hora > NOW()
      GROUP BY destino
      ORDER BY frecuencia DESC
      LIMIT 5
    `);

        // Obtener sugerencias basadas en la búsqueda
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
});
