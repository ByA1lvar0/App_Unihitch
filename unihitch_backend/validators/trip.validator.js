const { body } = require('express-validator');
const { validateResult } = require('./validateHelper');

const createTripValidation = [
    body('origen')
        .trim()
        .notEmpty().withMessage('El origen es requerido'),

    body('destino')
        .trim()
        .notEmpty().withMessage('El destino es requerido'),

    body('fecha_hora')
        .isISO8601().withMessage('Fecha inválida')
        .custom((value) => {
            if (new Date(value) <= new Date()) {
                throw new Error('La fecha del viaje debe ser futura');
            }
            return true;
        }),

    body('precio')
        .isFloat({ min: 0 }).withMessage('El precio debe ser mayor o igual a 0'),

    body('asientos_disponibles')
        .isInt({ min: 1, max: 6 }).withMessage('Asientos debe ser entre 1 y 6'),

    validateResult
];

module.exports = { createTripValidation };
