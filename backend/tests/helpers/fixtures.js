'use strict';

/**
 * Creates an isolated test scenario with unique usernames, so integration
 * tests can run repeatedly against the same database without clashing with
 * each other or with demo data. cleanup() removes everything it created
 * (audit log entries stay, by design: the log is append-only).
 */
const bcrypt = require('bcryptjs');
const { pool } = require('../../src/db/pool');

const CATS_PASSWORD = process.env.CATS_MOCK_PASSWORD;
const ADMIN_PASSWORD = 'Admin-Test-Password-1';

async function createScenario() {
  const tag = `t${Date.now().toString(36)}${Math.floor(Math.random() * 1e4)}`;
  const insertUser = async (suffix, name, role, passwordHash = null) => {
    const { rows } = await pool.query(
      `INSERT INTO users (cats_username, name, email, role, password_hash)
       VALUES ($1, $2, $3, $4, $5) RETURNING user_id, cats_username`,
      [`${tag}.${suffix}`, name, `${tag}.${suffix}@example.test`, role, passwordHash]
    );
    return { id: rows[0].user_id, username: rows[0].cats_username };
  };

  const admin = await insertUser(
    'admin',
    'Test Admin',
    'Admin',
    bcrypt.hashSync(ADMIN_PASSWORD, 4)
  );
  const jury1 = await insertUser('jury1', 'Test Jury 1', 'Jury');
  const jury2 = await insertUser('jury2', 'Test Jury 2', 'Jury');
  const outsider = await insertUser('jury3', 'Unassigned Jury', 'Jury');
  const student1 = await insertUser('stu1', 'Test Student 1', 'Student');
  const student2 = await insertUser('stu2', 'Test Student 2', 'Student');
  const otherStudent = await insertUser('stu3', 'Other Student', 'Student');

  const { rows } = await pool.query(
    `INSERT INTO projects (project_name, description, advisor_id, exam_datetime)
     VALUES ($1, 'Integration test project', $2, NOW()) RETURNING project_id`,
    [`Test Project ${tag}`, jury1.id]
  );
  const projectId = rows[0].project_id;

  await pool.query(
    'INSERT INTO project_members (project_id, student_id) VALUES ($1, $2), ($1, $3)',
    [projectId, student1.id, student2.id]
  );
  await pool.query('INSERT INTO jury_assignments (jury_id, project_id) VALUES ($1, $3), ($2, $3)', [
    jury1.id,
    jury2.id,
    projectId,
  ]);

  const criteria = (await pool.query('SELECT criteria_id FROM criteria ORDER BY criteria_id')).rows;

  async function cleanup() {
    const ids = [admin, jury1, jury2, outsider, student1, student2, otherStudent].map((u) => u.id);
    await pool.query('DELETE FROM projects WHERE project_id = $1', [projectId]);
    await pool.query('DELETE FROM users WHERE user_id = ANY($1::int[])', [ids]);
  }

  return {
    tag,
    projectId,
    criteriaIds: criteria.map((c) => c.criteria_id),
    users: { admin, jury1, jury2, outsider, student1, student2, otherStudent },
    passwords: { cats: CATS_PASSWORD, admin: ADMIN_PASSWORD },
    cleanup,
  };
}

module.exports = { createScenario };
