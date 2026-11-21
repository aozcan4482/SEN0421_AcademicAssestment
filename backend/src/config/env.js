'use strict';

/**
 * Loads configuration from environment variables (.env in development).
 * The application refuses to start if a required value is missing, so a
 * misconfiguration is caught at startup instead of at the first request.
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const REQUIRED = ['DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD'];

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

module.exports = Object.freeze({
  env: process.env.NODE_ENV || 'development',
  server: {
    host: process.env.HOST || '0.0.0.0',
    port: toInt(process.env.PORT, 3000),
  },
  db: {
    host: process.env.DB_HOST,
    port: toInt(process.env.DB_PORT, 5432),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    max: toInt(process.env.DB_POOL_MAX, 10),
  },
});
