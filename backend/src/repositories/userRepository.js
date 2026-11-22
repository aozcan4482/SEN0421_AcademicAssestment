'use strict';

const db = require('../db/pool');

// password_hash is selected only where it is needed (login), never returned
// to clients.
const PUBLIC_COLUMNS = 'user_id, cats_username, name, email, role';

async function findByUsername(username) {
  const { rows } = await db.query(
    `SELECT ${PUBLIC_COLUMNS}, password_hash
       FROM users
      WHERE cats_username = $1`,
    [username]
  );
  return rows[0] || null;
}

async function findById(userId) {
  const { rows } = await db.query(`SELECT ${PUBLIC_COLUMNS} FROM users WHERE user_id = $1`, [
    userId,
  ]);
  return rows[0] || null;
}

async function setPasswordHash(userId, passwordHash) {
  await db.query('UPDATE users SET password_hash = $2 WHERE user_id = $1', [userId, passwordHash]);
}

module.exports = { findByUsername, findById, setPasswordHash };
