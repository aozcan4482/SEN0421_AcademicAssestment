'use strict';

/**
 * Records security events in the immutable audit log.
 * Evaluation changes are logged by a database trigger; this service covers
 * events that happen only in the application (login, denied access).
 */
const auditRepository = require('../repositories/auditRepository');

const ACTIONS = Object.freeze({
  LOGIN_SUCCESS: 'LOGIN_SUCCESS',
  LOGIN_FAILURE: 'LOGIN_FAILURE',
  ACCESS_DENIED: 'ACCESS_DENIED',
});

/**
 * Logging must never break the request it describes: if the write fails the
 * error is reported on the server and the request continues.
 */
async function record(entry) {
  try {
    await auditRepository.insert(entry);
  } catch (err) {
    console.error('Audit log write failed:', err.message, entry.action);
  }
}

function requestContext(req) {
  return { ip: req.ip, method: req.method, path: req.originalUrl };
}

module.exports = { ACTIONS, record, requestContext };
