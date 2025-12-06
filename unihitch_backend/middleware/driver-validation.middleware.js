const pool = require('../config/db');

/**
 * Middleware para validar que el conductor tiene los documentos necesarios
 * Agentes externos requieren SOAT y LICENCIA aprobados para crear viajes
 */
const verifyDriverDocuments = async (req, res, next) => {
    try {
        const userId = req.user.id;

        // 1. Verificar si es agente externo
        const userResult = await pool.query(
            'SELECT es_agente_externo FROM usuario WHERE id = $1',
            [userId]
        );

        if (userResult.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        const isExternal = userResult.rows[0].es_agente_externo;

        // Si no es externo (es universitario), puede continuar sin restricciones de documentos
        if (!isExternal) {
            return next();
        }

        // 2. Si es externo, verificar documentos
        const docsResult = await pool.query(
            `SELECT tipo_documento, estado 
             FROM documentos_conductor 
             WHERE id_conductor = $1 AND estado = 'APROBADO'`,
            [userId]
        );

        const approvedDocs = docsResult.rows.map(doc => doc.tipo_documento);

        // Documentos obligatorios
        const requiredDocs = ['SOAT', 'LICENCIA'];
        const missingDocs = requiredDocs.filter(doc => !approvedDocs.includes(doc));

        if (missingDocs.length > 0) {
            return res.status(403).json({
                error: 'Documentos requeridos faltantes',
                detalle: `Para ofrecer viajes, debes tener aprobados: ${missingDocs.join(', ')}. Por favor sube tus documentos en la sección de perfil.`,
                documentos_faltantes: missingDocs
            });
        }

        next();
    } catch (error) {
        console.error('Error verificando documentos de conductor:', error);
        res.status(500).json({ error: 'Error verificando documentos' });
    }
};

module.exports = { verifyDriverDocuments };
