const { check, validationResult } = require('express-validator');
const validateHelper = require('./validateHelper');

const ratingValidation = [
    check('id_viaje')
        .exists()
        .withMessage('El ID del viaje es requerido')
        .isInt()
        .withMessage('El ID del viaje debe ser un número entero'),
    check('id_destinatario')
        .exists()
        .withMessage('El ID del destinatario es requerido')
        .isInt()
        .withMessage('El ID del destinatario debe ser un número entero'),
    check('puntuacion')
        .exists()
        .withMessage('La puntuación es requerida')
        .isInt({ min: 1, max: 5 })
        .withMessage('La puntuación debe estar entre 1 y 5'),
    check('comentario')
        .optional()
        .isLength({ max: 500 })
        .withMessage('El comentario no puede exceder los 500 caracteres'),
    (req, res, next) => {
        validateHelper(req, res, next);
    }
];

module.exports = { ratingValidation };
