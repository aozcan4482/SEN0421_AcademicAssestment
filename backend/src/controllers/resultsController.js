'use strict';

const scoringService = require('../services/scoringService');
const HttpError = require('../utils/HttpError');

/**
 * POST /api/admin/projects/:projectId/results
 * Calculates and stores the weighted final score of every project member.
 */
async function calculate(req, res) {
  const projectId = Number(req.params.projectId);
  if (!Number.isInteger(projectId) || projectId <= 0) {
    throw new HttpError(400, 'Invalid project id');
  }
  res.json(await scoringService.calculateProjectResults(projectId, req.user.userId));
}

module.exports = { calculate };
