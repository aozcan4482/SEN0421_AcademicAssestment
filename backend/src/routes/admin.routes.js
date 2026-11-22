'use strict';

/** Administrator-only routes. Every route here requires the Admin role. */
const express = require('express');
const auditController = require('../controllers/auditController');
const resultsController = require('../controllers/resultsController');
const authenticate = require('../middleware/authenticate');
const { requireRole } = require('../middleware/authorize');

const router = express.Router();

router.use(authenticate, requireRole('Admin'));

router.get('/audit-log', auditController.list);
router.get('/audit-log/verify', auditController.verify);
router.post('/projects/:projectId/results', resultsController.calculate);

module.exports = router;
