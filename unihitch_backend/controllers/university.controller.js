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

module.exports = { getUniversities, getCareers };
