'use strict';

/**
 * Data access for the criteria table. Repositories contain only SQL;
 * business rules live in services and HTTP concerns in controllers.
 */
const db = require('../db/pool');

async function findAll() {
  const { rows } = await db.query(
    `SELECT criteria_id, criteria_name, weight::float AS weight
       FROM criteria
      ORDER BY criteria_id`
  );
  return rows;
}

module.exports = { findAll };
