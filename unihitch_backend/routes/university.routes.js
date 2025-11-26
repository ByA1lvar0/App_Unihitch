const express = require('express');
const router = express.Router();
const universityController = require('../controllers/university.controller');

router.get('/universidades', universityController.getUniversities);
router.get('/carreras/:universidadId', universityController.getCareers);

module.exports = router;
