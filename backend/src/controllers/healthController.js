'use strict';

const db = require('../db/pool');

/**
 * GET /api/health - liveness and database connectivity check.
 * Returns 200 when the database answers, 503 otherwise. Used by developers,
 * the mobile client's server settings screen and, later, the CI pipeline.
 */
async function check(req, res) {
  try {
    await db.query('SELECT 1');
    res.json({ status: 'ok', database: 'up', time: new Date().toISOString() });
  } catch {
    res.status(503).json({ status: 'degraded', database: 'down', time: new Date().toISOString() });
  }
}

module.exports = { check };
