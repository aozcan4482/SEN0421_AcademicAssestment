'use strict';

const db = require('../db/pool');

/**
 * GET /api/admin/audit-log?limit=50&before=<audit_id>
 * Most recent entries first; `before` pages backwards through older entries.
 */
async function list(req, res) {
  const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 50, 1), 200);
  const before = Number.parseInt(req.query.before, 10);
  const { rows } = await db.query(
    `SELECT a.audit_id, a.occurred_at, a.actor_user_id, u.name AS actor_name,
            a.action, a.entity_type, a.entity_id, a.project_id, a.student_id,
            a.criteria_id, a.old_value, a.new_value, a.details
       FROM audit_log a
       LEFT JOIN users u ON u.user_id = a.actor_user_id
      WHERE ($1::bigint IS NULL OR a.audit_id < $1)
      ORDER BY a.audit_id DESC
      LIMIT $2`,
    [Number.isNaN(before) ? null : before, limit]
  );
  res.json(rows);
}

/**
 * GET /api/admin/audit-log/verify
 * Recomputes the hash chain. `intact: false` means at least one entry was
 * changed or removed outside the application; `first_invalid_id` shows where.
 */
async function verify(req, res) {
  const { rows } = await db.query(
    'SELECT verify_audit_chain() AS first_invalid_id, (SELECT count(*) FROM audit_log)::int AS entries'
  );
  const { first_invalid_id: firstInvalidId, entries } = rows[0];
  res.json({
    intact: firstInvalidId === null,
    entries,
    first_invalid_id: firstInvalidId === null ? null : Number(firstInvalidId),
    checked_at: new Date().toISOString(),
  });
}

module.exports = { list, verify };
