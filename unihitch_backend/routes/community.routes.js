const express = require('express');
const router = express.Router();
const communityController = require('../controllers/community.controller');

router.get('/messages/:universidadId', communityController.getMessages);
router.post('/messages', communityController.sendMessage);
router.get('/members/:universidadId', communityController.getMembers);

module.exports = router;
