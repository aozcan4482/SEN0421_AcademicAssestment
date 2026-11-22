'use strict';

/**
 * Authentication rules (WP-02 design):
 *  - Admin accounts sign in locally with a bcrypt-hashed password, so the
 *    admin panel stays usable when CATS is down (RSK-03).
 *  - Jury and Student accounts sign in through CATS. A successful CATS login
 *    is not enough: the user must also be registered in this system, which
 *    is what assigns the role.
 * On success a signed JWT is issued; it carries only the user id and role.
 */
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const config = require('../config/env');
const userRepository = require('../repositories/userRepository');
const catsClient = require('./catsClient');
const HttpError = require('../utils/HttpError');

const BCRYPT_ROUNDS = 12;

// Compared against when the username does not exist, so a wrong username
// takes as long as a wrong password and cannot be discovered by timing.
const DUMMY_HASH = bcrypt.hashSync('timing-equaliser', BCRYPT_ROUNDS);

// One message for every credential failure: it must not reveal whether the
// username or the password was wrong.
const INVALID_CREDENTIALS = 'Invalid username or password';

function toPublicUser(user) {
  return {
    user_id: user.user_id,
    username: user.cats_username,
    name: user.name,
    email: user.email,
    role: user.role,
  };
}

function issueToken(user) {
  return jwt.sign({ role: user.role }, config.auth.jwtSecret, {
    subject: String(user.user_id),
    expiresIn: config.auth.jwtExpiresIn,
    algorithm: 'HS256',
  });
}

async function loginLocal(user, password) {
  const ok = await bcrypt.compare(password, user.password_hash);
  return ok ? user : null;
}

async function loginWithCats(user, username, password) {
  let accepted;
  try {
    accepted = await catsClient.verifyCredentials(username, password);
  } catch (err) {
    if (err instanceof catsClient.CatsUnavailableError) {
      throw new HttpError(503, 'Authentication service is temporarily unavailable');
    }
    throw err;
  }
  if (!accepted) return { user: null, reason: 'cats_rejected' };
  if (!user) return { user: null, reason: 'not_registered', authenticated: true };
  return { user };
}

/**
 * @returns {Promise<{ token: string, user: object }>}
 * @throws {HttpError} 401 for bad credentials, 403 if CATS accepts the user but
 *   they are not registered, 503 if CATS is unreachable
 */
async function login(username, password) {
  const user = await userRepository.findByUsername(username);

  // Local login: only Admin accounts that have a password set.
  if (user && user.role === 'Admin') {
    if (!user.password_hash) {
      throw Object.assign(new HttpError(401, INVALID_CREDENTIALS), { reason: 'admin_no_password' });
    }
    const ok = await loginLocal(user, password);
    if (!ok)
      throw Object.assign(new HttpError(401, INVALID_CREDENTIALS), { reason: 'bad_password' });
    return { token: issueToken(user), user: toPublicUser(user) };
  }

  const result = await loginWithCats(user, username, password);
  if (!result.user) {
    if (result.reason === 'not_registered') {
      throw Object.assign(
        new HttpError(
          403,
          'Your account is not registered in this system. Contact the administrator.'
        ),
        { reason: result.reason }
      );
    }
    if (!user) await bcrypt.compare(password, DUMMY_HASH); // equalise timing
    throw Object.assign(new HttpError(401, INVALID_CREDENTIALS), { reason: result.reason });
  }
  return { token: issueToken(result.user), user: toPublicUser(result.user) };
}

/**
 * Verifies a token and returns its claims.
 * @returns {{ userId: number, role: string }}
 * @throws {HttpError} 401 if the token is missing, invalid or expired
 */
function verifyToken(token) {
  try {
    const payload = jwt.verify(token, config.auth.jwtSecret, { algorithms: ['HS256'] });
    return { userId: Number(payload.sub), role: payload.role };
  } catch (err) {
    const message = err.name === 'TokenExpiredError' ? 'Session expired' : 'Invalid token';
    throw new HttpError(401, message);
  }
}

function hashPassword(password) {
  return bcrypt.hash(password, BCRYPT_ROUNDS);
}

module.exports = { login, verifyToken, hashPassword, toPublicUser };
