'use strict';

/**
 * API route table. Each module registers its routes here under /api.
 * New modules (auth, projects, evaluations, ...) are added as separate
 * router files so that parallel work does not touch the same file.
 */
const express = require('express');
const healthController = require('../controllers/healthController');
const criteriaController = require('../controllers/criteriaController');
const authenticate = require('../middleware/authenticate');
const authRoutes = require('./auth.routes');
const adminRoutes = require('./admin.routes');
const juryRoutes = require('./jury.routes');

const router = express.Router();

// Public
router.get('/health', healthController.check);
router.use('/auth', authRoutes);

// Authenticated
router.get('/criteria', authenticate, criteriaController.list);
router.use('/admin', adminRoutes);
router.use('/jury', juryRoutes);

module.exports = router;
