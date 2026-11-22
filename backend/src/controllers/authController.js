'use strict';

const authService = require('../services/authService');
const auditService = require('../services/auditService');
const userRepository = require('../repositories/userRepository');
const HttpError = require('../utils/HttpError');

function readCredentials(body) {
  const username = typeof body?.username === 'string' ? body.username.trim() : '';
  const password = typeof body?.password === 'string' ? body.password : '';
  if (!username || !password || username.length > 100 || password.length > 200) {
    throw new HttpError(400, 'Username and password are required');
  }
  return { username, password };
}

/**
 * POST /api/auth/login  { username, password } -> { token, user }
 * The password is never logged; only the username and outcome are audited.
 */
async function login(req, res) {
  const { username, password } = readCredentials(req.body);
  const context = auditService.requestContext(req);
  try {
    const result = await authService.login(username, password);
    await auditService.record({
      actorUserId: result.user.user_id,
      action: auditService.ACTIONS.LOGIN_SUCCESS,
      details: { ...context, username },
    });
    res.json(result);
  } catch (err) {
    if (err instanceof HttpError && (err.status === 401 || err.status === 403)) {
      await auditService.record({
        action: auditService.ACTIONS.LOGIN_FAILURE,
        details: { ...context, username, reason: err.reason || 'unknown' },
      });
    }
    throw err;
  }
}

/** GET /api/auth/me - the signed-in user's profile. */
async function me(req, res) {
  const user = await userRepository.findById(req.user.userId);
  if (!user) throw new HttpError(401, 'Account no longer exists');
  res.json(authService.toPublicUser(user));
}

module.exports = { login, me };
