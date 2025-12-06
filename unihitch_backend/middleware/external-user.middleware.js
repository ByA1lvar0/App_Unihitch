const pool = require('../config/db');

/**
 * Middleware para bloquear agentes externos de funcionalidades universitarias
 */
const blockExternalUsers = (req, res, next) => {
    if (req.user && req.user.es_agente_externo) {
        return res.status(403).json({
            error: 'Esta funcionalidad es solo para usuarios universitarios',
            tipo_usuario: 'AGENTE_EXTERNO',
            mensaje: 'Como conductor externo, solo puedes ofrecer viajes y comunicarte con tus pasajeros'
        });
    }
    next();
};

/**
 * Middleware para funcionalidades exclusivas de agentes externos
 */
const onlyExternalUsers = (req, res, next) => {
    if (req.user && !req.user.es_agente_externo) {
        return res.status(403).json({
            error: 'Esta funcionalidad es solo para agentes externos'
        });
    }
    next();
};

/**
 * Middleware para verificar que el usuario tenga universidad asignada
 */
const requireUniversity = (req, res, next) => {
    if (req.user && !req.user.id_universidad) {
        return res.status(403).json({
            error: 'Debes pertenecer a una universidad para acceder a esta funcionalidad'
        });
    }
    next();
};

module.exports = {
    blockExternalUsers,
    onlyExternalUsers,
    requireUniversity
};
