'use strict';

/**
 * Role-based and resource-based authorisation (WP-02 role-permission matrix).
 * Must run after `authenticate`. Every refusal is written to the audit log.
 */
const HttpError = require('../utils/HttpError');
const auditService = require('../services/auditService');
const assignmentRepository = require('../repositories/assignmentRepository');

function deny(req, reason, extra = {}) {
  auditService.record({
    actorUserId: req.user?.userId,
    action: auditService.ACTIONS.ACCESS_DENIED,
    details: { ...auditService.requestContext(req), role: req.user?.role, reason },
    ...extra,
  });
  return new HttpError(403, 'Access denied');
}

/**
 * Allows the request only for the given roles.
 * Usage: router.get('/admin/...', authenticate, requireRole('Admin'), handler)
 */
function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return next(deny(req, 'role_not_allowed'));
    }
    return next();
  };
}

/**
 * Allows a jury member to act only on projects assigned to them, so one
 * jury member can never read or change another's evaluations.
 * @param {string} param name of the route parameter holding the project id
 */
function requireJuryAssignment(param = 'projectId') {
  return async (req, res, next) => {
    const projectId = Number(req.params[param]);
    if (!Number.isInteger(projectId) || projectId <= 0) {
      return next(new HttpError(400, 'Invalid project id'));
    }
    const assigned = await assignmentRepository.isJuryAssigned(req.user.userId, projectId);
    if (!assigned) {
      return next(deny(req, 'not_assigned_to_project', { projectId }));
    }
    req.projectId = projectId;
    return next();
  };
}

module.exports = { requireRole, requireJuryAssignment };
