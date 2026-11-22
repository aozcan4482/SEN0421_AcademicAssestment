'use strict';

/**
 * Write operations on evaluations. All functions take a transaction client:
 * they are always called inside db.withActor(), so the audit trigger knows
 * which user made the change.
 */

async function isProjectMember(client, projectId, studentId) {
  const { rowCount } = await client.query(
    'SELECT 1 FROM project_members WHERE project_id = $1 AND student_id = $2',
    [projectId, studentId]
  );
  return rowCount > 0;
}

/**
 * Locks this jury member's rows for one student until the transaction ends
 * and reports whether they were already submitted.
 */
async function lockStudentRows(client, juryId, projectId, studentId) {
  const { rows } = await client.query(
    `SELECT criteria_id, is_submitted
       FROM evaluations
      WHERE jury_id = $1 AND project_id = $2 AND student_id = $3
      FOR UPDATE`,
    [juryId, projectId, studentId]
  );
  return rows;
}

async function upsertScore(client, { juryId, projectId, studentId, criteriaId, score, comment }) {
  await client.query(
    `INSERT INTO evaluations (jury_id, project_id, student_id, criteria_id, score, comment)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (jury_id, project_id, student_id, criteria_id)
     DO UPDATE SET score = EXCLUDED.score,
                   comment = EXCLUDED.comment,
                   updated_at = NOW()
     WHERE evaluations.is_submitted = FALSE`,
    [juryId, projectId, studentId, criteriaId, score, comment]
  );
}

async function markSubmitted(client, juryId, projectId, studentId) {
  await client.query(
    `UPDATE evaluations
        SET is_submitted = TRUE, submitted_at = NOW(), updated_at = NOW()
      WHERE jury_id = $1 AND project_id = $2 AND student_id = $3 AND is_submitted = FALSE`,
    [juryId, projectId, studentId]
  );
}

/**
 * Keeps the assignment and project status in step with the scores:
 *  - the assignment is completed once every member is submitted by this jury;
 *  - the project moves from Pending to In Progress at the first score, and to
 *    Completed when every assigned jury member has completed.
 */
async function refreshProgress(client, juryId, projectId) {
  await client.query(
    `UPDATE jury_assignments ja
        SET is_completed = done.complete,
            completed_at = CASE WHEN done.complete THEN COALESCE(ja.completed_at, NOW()) END
       FROM (
         SELECT (SELECT count(*) FROM project_members WHERE project_id = $2)
                  * (SELECT count(*) FROM criteria)
                = count(*) FILTER (WHERE e.is_submitted) AS complete
           FROM evaluations e
          WHERE e.jury_id = $1 AND e.project_id = $2
       ) done
      WHERE ja.jury_id = $1 AND ja.project_id = $2`,
    [juryId, projectId]
  );
  await client.query(
    `UPDATE projects p
        SET status = CASE
              WHEN NOT EXISTS (SELECT 1 FROM jury_assignments
                                WHERE project_id = p.project_id AND NOT is_completed)
                THEN 'Completed'
              ELSE 'In Progress'
            END
      WHERE p.project_id = $1 AND p.status IN ('Pending', 'In Progress')`,
    [projectId]
  );
}

module.exports = { isProjectMember, lockStudentRows, upsertScore, markSubmitted, refreshProgress };
