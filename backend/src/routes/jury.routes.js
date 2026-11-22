'use strict';

/**
 * Jury member routes. Every route requires the Jury role; routes for a
 * specific project also require that the jury member is assigned to it.
 */
const express = require('express');
const juryController = require('../controllers/juryController');
const authenticate = require('../middleware/authenticate');
const { requireRole, requireJuryAssignment } = require('../middleware/authorize');

const router = express.Router();

router.use(authenticate, requireRole('Jury'));

router.get('/projects', juryController.listProjects);
router.get('/projects/:projectId', requireJuryAssignment(), juryController.getProject);
router.put(
  '/projects/:projectId/students/:studentId/evaluation',
  requireJuryAssignment(),
  juryController.saveEvaluation
);

module.exports = router;
