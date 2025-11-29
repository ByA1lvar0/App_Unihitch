const { body } = require('express-validator');
const { validateResult } = require('./validateHelper');

const registerValidation = [
    body('nombre')
        .trim()
        .notEmpty().withMessage('El nombre es requerido')
        .isLength({ min: 3 }).withMessage('El nombre debe tener al menos 3 caracteres'),

    body('correo')
        .trim()
        .isEmail().withMessage('Debe ser un correo válido')
        .normalizeEmail(),

    body('password')
        .isLength({ min: 6 }).withMessage('La contraseña debe tener al menos 6 caracteres'),

    body('telefono')
        .trim()
        .isNumeric().withMessage('El teléfono debe contener solo números')
        .isLength({ min: 9, max: 9 }).withMessage('El teléfono debe tener 9 dígitos'),

    validateResult
];

const loginValidation = [
    body('correo')
        .trim()
        .isEmail().withMessage('Debe ser un correo válido'),

    body('password')
        .notEmpty().withMessage('La contraseña es requerida'),

    validateResult
];

module.exports = { registerValidation, loginValidation };
