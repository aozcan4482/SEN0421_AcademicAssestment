'use strict';

/**
 * Read queries for the jury member's view: assigned projects, their members
 * and the jury member's own scores. Every query is scoped by jury_id, so a
 * jury member can only ever see their own evaluations.
 */
const db = require('../db/pool');

/**
 * Projects assigned to a jury member, with per-student progress.
 * A student counts as "evaluated" when every criterion has a score and as
 * "submitted" when those scores have been submitted.
 */
async function findAssignedProjects(juryId) {
  const { rows } = await db.query(
    `WITH criteria_count AS (SELECT count(*)::int AS n FROM criteria),
          per_student AS (
            SELECT pm.project_id, pm.student_id, u.name, u.cats_username,
                   count(e.evaluation_id)::int                      AS scored,
                   count(e.evaluation_id) FILTER (WHERE e.is_submitted)::int AS submitted
              FROM jury_assignments ja
              JOIN project_members pm ON pm.project_id = ja.project_id
              JOIN users u            ON u.user_id = pm.student_id
              LEFT JOIN evaluations e ON e.jury_id = ja.jury_id
                                     AND e.project_id = pm.project_id
                                     AND e.student_id = pm.student_id
             WHERE ja.jury_id = $1
             GROUP BY pm.project_id, pm.student_id, u.name, u.cats_username
          )
     SELECT p.project_id, p.project_name, p.description, p.exam_datetime, p.status,
            adv.name AS advisor_name,
            ja.is_completed, ja.completed_at,
            COALESCE(json_agg(json_build_object(
                'student_id', s.student_id,
                'name', s.name,
                'username', s.cats_username,
                'evaluated', s.scored = cc.n,
                'submitted', s.submitted = cc.n
              ) ORDER BY s.name) FILTER (WHERE s.student_id IS NOT NULL), '[]') AS members
       FROM jury_assignments ja
       JOIN projects p    ON p.project_id = ja.project_id
       LEFT JOIN users adv ON adv.user_id = p.advisor_id
       LEFT JOIN per_student s ON s.project_id = p.project_id
       CROSS JOIN criteria_count cc
      WHERE ja.jury_id = $1
      GROUP BY p.project_id, adv.name, ja.is_completed, ja.completed_at
      ORDER BY p.exam_datetime NULLS LAST, p.project_id`,
    [juryId]
  );
  return rows;
}

async function findProject(projectId) {
  const { rows } = await db.query(
    `SELECT p.project_id, p.project_name, p.description, p.exam_datetime, p.status,
            adv.name AS advisor_name
       FROM projects p
       LEFT JOIN users adv ON adv.user_id = p.advisor_id
      WHERE p.project_id = $1`,
    [projectId]
  );
  return rows[0] || null;
}

async function findMembers(projectId) {
  const { rows } = await db.query(
    `SELECT u.user_id AS student_id, u.name, u.cats_username AS username
       FROM project_members pm
       JOIN users u ON u.user_id = pm.student_id
      WHERE pm.project_id = $1
      ORDER BY u.name`,
    [projectId]
  );
  return rows;
}

async function findOwnScores(juryId, projectId) {
  const { rows } = await db.query(
    `SELECT student_id, criteria_id, score, comment, is_submitted, submitted_at, updated_at
       FROM evaluations
      WHERE jury_id = $1 AND project_id = $2`,
    [juryId, projectId]
  );
  return rows;
}

module.exports = { findAssignedProjects, findProject, findMembers, findOwnScores };
