'use strict';

/**
 * Verifies a username/password pair against the university CATS portal.
 *
 * The credentials are forwarded once and never stored or logged by this
 * application (WP-02, ISO/IEC 27001:2022 A 8.5). CATS answers a successful
 * login with an HTTP 302 redirect; any other status means failure.
 *
 * CATS_MODE=mock replaces the call for local development: every username
 * is accepted with the password configured in CATS_MOCK_PASSWORD. The mock
 * is refused at startup when NODE_ENV=production.
 */
const config = require('../config/env');

class CatsUnavailableError extends Error {
  constructor(cause) {
    super('CATS service is unreachable');
    this.name = 'CatsUnavailableError';
    this.cause = cause;
  }
}

async function verifyLive(username, password) {
  const body = new URLSearchParams({ eid: username, pw: password, submit: 'Login' });
  let response;
  try {
    response = await fetch(config.cats.loginUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
      redirect: 'manual',
      signal: AbortSignal.timeout(config.cats.timeoutMs),
    });
  } catch (err) {
    throw new CatsUnavailableError(err);
  }
  return response.status === 302;
}

async function verifyMock(_username, password) {
  return config.cats.mockPassword !== '' && password === config.cats.mockPassword;
}

/**
 * @returns {Promise<boolean>} true if CATS accepts the credentials
 * @throws {CatsUnavailableError} if CATS cannot be reached
 */
function verifyCredentials(username, password) {
  return config.cats.mode === 'mock'
    ? verifyMock(username, password)
    : verifyLive(username, password);
}

module.exports = { verifyCredentials, CatsUnavailableError };
