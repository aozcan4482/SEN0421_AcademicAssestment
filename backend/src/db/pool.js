'use strict';

/**
 * Shared PostgreSQL connection pool.
 *
 * All database access goes through this module. Queries must always use
 * parameter placeholders ($1, $2, ...) and never string concatenation,
 * so user input can never be executed as SQL.
 */
const { Pool } = require('pg');
const config = require('../config/env');

const pool = new Pool({
  ...config.db,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

// An idle client can lose its connection (e.g. the database restarts).
// Log it instead of letting the error crash the process.
pool.on('error', (err) => {
  console.error('Unexpected error on idle PostgreSQL client:', err.message);
});

/**
 * Runs a single parameterised query.
 * @param {string} text   SQL with $1, $2, ... placeholders
 * @param {Array}  params Values for the placeholders
 */
function query(text, params = []) {
  return pool.query(text, params);
}

/**
 * Runs `work` inside one transaction. Everything is committed together, or
 * rolled back together if `work` throws.
 * @param {(client: import('pg').PoolClient) => Promise<T>} work
 * @returns {Promise<T>}
 * @template T
 */
async function withTransaction(work) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await work(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * Like withTransaction, but also tells the database who is acting.
 * Database triggers read this value and write it to the audit log, so every
 * change made through the API is attributed to the authenticated user.
 * The setting is local to the transaction and disappears at COMMIT/ROLLBACK.
 * @param {number} userId
 * @param {(client: import('pg').PoolClient) => Promise<T>} work
 * @returns {Promise<T>}
 * @template T
 */
function withActor(userId, work) {
  return withTransaction(async (client) => {
    await client.query("SELECT set_config('app.current_user_id', $1, true)", [String(userId)]);
    return work(client);
  });
}

module.exports = { pool, query, withTransaction, withActor };
