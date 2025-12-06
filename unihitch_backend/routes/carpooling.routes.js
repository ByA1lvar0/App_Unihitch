const express = require('express');
const router = express.Router();
const carpoolingController = require('../controllers/carpooling.controller');

// Get all groups (with optional filters)
router.get('/groups', carpoolingController.getGroups);

// Create new group
router.post('/groups', carpoolingController.createGroup);

// Get group details
router.get('/groups/:id', carpoolingController.getGroupDetails);

// Join group
router.post('/groups/:id/join', carpoolingController.joinGroup);

// Leave group
router.post('/groups/:id/leave', carpoolingController.leaveGroup);

// Get user's groups
router.get('/my-groups/:userId', carpoolingController.getMyGroups);

module.exports = router;
