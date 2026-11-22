'use strict';

/**
 * Loads configuration from environment variables (.env in development).
 * The application refuses to start if a required value is missing, so a
 * misconfiguration is caught at startup instead of at the first request.
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const REQUIRED = ['DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD', 'JWT_SECRET'];

const missing = REQUIRED.filter((key) => !process.env[key]);
if (missing.length > 0) {
  throw new Error(
    `Missing required environment variables: ${missing.join(', ')}. ` +
      'Copy backend/.env.example to backend/.env and fill it in.'
  );
}

function toInt(value, fallback) {
  const parsed = Number.parseInt(value, 10);
  return Number.isNaN(parsed) ? fallback : parsed;
}

const env = process.env.NODE_ENV || 'development';

// A short or guessable secret would let anyone forge tokens.
if (process.env.JWT_SECRET.length < 32) {
  throw new Error('JWT_SECRET must be at least 32 characters long.');
}

const catsMode = (process.env.CATS_MODE || 'live').toLowerCase();
if (!['live', 'mock'].includes(catsMode)) {
  throw new Error('CATS_MODE must be "live" or "mock".');
}
// The mock exists only to develop without real CATS accounts.
if (catsMode === 'mock' && env === 'production') {
  throw new Error('CATS_MODE=mock is not allowed when NODE_ENV=production.');
}

module.exports = Object.freeze({
  env,
  server: {
    host: process.env.HOST || '0.0.0.0',
    port: toInt(process.env.PORT, 3000),
    // Set when the API runs behind a TLS-terminating reverse proxy (RSK-02),
    // so client IPs and rate limits use the real address.
    trustProxy: process.env.TRUST_PROXY === 'true',
  },
  db: {
    host: process.env.DB_HOST,
    port: toInt(process.env.DB_PORT, 5432),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    max: toInt(process.env.DB_POOL_MAX, 10),
  },
  auth: {
    jwtSecret: process.env.JWT_SECRET,
    jwtExpiresIn: process.env.JWT_EXPIRES_IN || '8h',
    loginRateLimit: toInt(process.env.LOGIN_RATE_LIMIT, 10),
  },
  cats: {
    mode: catsMode,
    loginUrl: process.env.CATS_LOGIN_URL || 'https://cats.iku.edu.tr/portal/xlogin',
    timeoutMs: toInt(process.env.CATS_TIMEOUT_MS, 10000),
    mockPassword: process.env.CATS_MOCK_PASSWORD || '',
  },
});
