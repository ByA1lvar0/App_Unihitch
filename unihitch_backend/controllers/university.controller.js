const pool = require('../config/db');

const getUniversities = async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM universidad ORDER BY nombre');
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener universidades' });
    }
};

const getCareers = async (req, res) => {
    try {
        const { universidadId } = req.params;
        const result = await pool.query(
            'SELECT * FROM carrera WHERE id_universidad = $1 AND activo = true ORDER BY nombre',
            [universidadId]
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener carreras' });
    }
};

// Detectar universidad por dominio de correo
const detectUniversityByEmail = async (req, res) => {
    try {
        const { email } = req.body;
        const emailLower = email.toLowerCase().trim();

        // Mapeo de dominios a universidades
        const domainMap = {
            'utp.edu.pe': 'Universidad Tecnológica del Perú',
            'alumnos.unp.edu.pe': 'Universidad Nacional de Piura',
            'ucvvirtual.edu.pe': 'Universidad César Vallejo',
            'udep.edu.pe': 'Universidad de Piura',
            'upn.edu.pe': 'Universidad Privada del Norte',
            'usmp.edu.pe': 'Universidad de San Martín de Porres',
        };

        // Extraer dominio del correo
        if (!emailLower.includes('@')) {
            return res.json({ detected: false });
        }

        const domain = emailLower.split('@')[1];

        // Buscar universidad por dominio
        for (const [key, value] of Object.entries(domainMap)) {
            if (domain && domain.includes(key)) {
                const university = await pool.query(
                    'SELECT id, nombre FROM universidad WHERE nombre ILIKE $1',
                    [`%${value}%`]
                );

                if (university.rows.length > 0) {
                    return res.json({
                        detected: true,
                        university: university.rows[0]
                    });
                }
            }
        }

        res.json({ detected: false });
    } catch (error) {
        console.error('Error detecting university:', error);
        res.status(500).json({ error: 'Error al detectar universidad' });
    }
};

module.exports = { getUniversities, getCareers, detectUniversityByEmail };
