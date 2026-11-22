'use strict';

const db = require('../db/pool');

/**
 * Appends one entry to the audit log. Hashing and chaining are done by the
 * database trigger; the application can only insert, never change entries.
 * @param {object} entry
 * @param {import('pg').PoolClient} [client] use inside an open transaction
 */
async function insert(entry, client = db) {
  await client.query(
    `INSERT INTO audit_log (actor_user_id, action, entity_type, entity_id,
                            project_id, student_id, criteria_id,
                            old_value, new_value, details)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
    [
      entry.actorUserId ?? null,
      entry.action,
      entry.entityType ?? null,
      entry.entityId ?? null,
      entry.projectId ?? null,
      entry.studentId ?? null,
      entry.criteriaId ?? null,
      entry.oldValue ?? null,
      entry.newValue ?? null,
      entry.details ?? null,
    ]
  );
}

module.exports = { insert };
