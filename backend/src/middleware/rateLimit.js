'use strict';

/**
 * Brute-force protection for the login endpoint: after too many failed
 * attempts from one address, further attempts are refused for a while.
 * Successful logins do not count towards the limit.
 */
const { rateLimit } = require('express-rate-limit');
const config = require('../config/env');
const auditService = require('../services/auditService');

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: config.auth.loginRateLimit,
  skipSuccessfulRequests: true,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  handler: (req, res, next, options) => {
    auditService.record({
      action: auditService.ACTIONS.LOGIN_FAILURE,
      details: {
        ...auditService.requestContext(req),
        username: typeof req.body?.username === 'string' ? req.body.username : null,
        reason: 'rate_limited',
      },
    });
    res.status(options.statusCode).json({
      error: 'Too many failed login attempts. Try again in 15 minutes.',
    });
  },
});

module.exports = { loginLimiter };
