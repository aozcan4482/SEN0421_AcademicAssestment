'use strict';

const evaluationService = require('../services/evaluationService');

/** GET /api/jury/projects */
async function listProjects(req, res) {
  res.json(await evaluationService.listAssignedProjects(req.user.userId));
}

/** GET /api/jury/projects/:projectId */
async function getProject(req, res) {
  res.json(await evaluationService.getProjectForJury(req.user.userId, req.projectId));
}

/**
 * PUT /api/jury/projects/:projectId/students/:studentId/evaluation
 * Body: { scores: [{ criteria_id, score, comment? }], submit?: boolean }
 */
async function saveEvaluation(req, res) {
  const project = await evaluationService.saveStudentEvaluation(
    req.user.userId,
    req.projectId,
    Number(req.params.studentId),
    req.body
  );
  res.json(project);
}

module.exports = { listProjects, getProject, saveEvaluation };
