'use strict';

/**
 * Requires a valid "Authorization: Bearer <token>" header.
 * On success the caller is available as req.user = { userId, role }.
 */
const authService = require('../services/authService');
const HttpError = require('../utils/HttpError');

function authenticate(req, res, next) {
  const header = req.get('Authorization') || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) {
    return next(new HttpError(401, 'Authentication required'));
  }
  req.user = authService.verifyToken(token);
  return next();
}

module.exports = authenticate;
