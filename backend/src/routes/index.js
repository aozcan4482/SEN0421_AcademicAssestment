'use strict';

/**
 * API route table. Each module registers its routes here under /api.
 * New modules (auth, projects, evaluations, ...) are added as separate
 * router files so that parallel work does not touch the same file.
 */
const express = require('express');
const healthController = require('../controllers/healthController');
const criteriaController = require('../controllers/criteriaController');

const router = express.Router();

router.get('/health', healthController.check);
router.get('/criteria', criteriaController.list);

module.exports = router;
