'use strict';

/**
 * Weighted average scoring (IEEE 1016 - Algorithm view).
 *
 * For one student:
 *   1. Each jury member's total is the weighted sum of their criterion
 *      scores:   total_j = Σ (score_jc × weight_c)
 *      Because the weights sum to 1.0, every total is on the 0-100 scale.
 *   2. Only jury members who have SUBMITTED a score for EVERY criterion are
 *      counted; drafts and incomplete sets are ignored.
 *   3. The final score is the arithmetic mean of the counted jury totals,
 *      rounded to two decimals.
 *
 * The calculation is a pure function (no database access), so it can be
 * verified exhaustively by unit tests.
 */
const db = require('../db/pool');
const HttpError = require('../utils/HttpError');

/**
 * Rounds half away from zero to `digits` decimals. Shifting the decimal point
 * in the string form avoids binary float errors such as 1.005 -> 1.00.
 */
function round(value, digits = 2) {
  const sign = value < 0 ? -1 : 1;
  const text = String(Math.abs(value));
  if (text.includes('e')) return sign * (Math.round(Math.abs(value) * 10 ** digits) / 10 ** digits);
  return sign * Number(`${Math.round(Number(`${text}e${digits}`))}e-${digits}`);
}

/**
 * @param {Array<{ jury_id: number, criteria_id: number, score: number, is_submitted: boolean }>} evaluations
 *   all evaluations of ONE student
 * @param {Array<{ criteria_id: number, weight: number }>} criteria
 * @returns {{ finalScore: number|null, juryCount: number, juryTotals: Array<{ jury_id: number, total: number }> }}
 *   finalScore is null when no jury member has a complete submitted set
 */
function calculateStudentScore(evaluations, criteria) {
  if (!Array.isArray(criteria) || criteria.length === 0) {
    throw new Error('At least one criterion is required');
  }
  const weightById = new Map(criteria.map((c) => [c.criteria_id, Number(c.weight)]));

  const byJury = new Map();
  for (const e of evaluations) {
    if (!e.is_submitted || !weightById.has(e.criteria_id)) continue;
    if (!byJury.has(e.jury_id)) byJury.set(e.jury_id, new Map());
    byJury.get(e.jury_id).set(e.criteria_id, Number(e.score));
  }

  const juryTotals = [];
  for (const [juryId, scores] of byJury) {
    if (scores.size !== weightById.size) continue; // incomplete set
    let total = 0;
    for (const [criteriaId, weight] of weightById) total += scores.get(criteriaId) * weight;
    juryTotals.push({ jury_id: juryId, total: round(total) });
  }
  juryTotals.sort((a, b) => a.jury_id - b.jury_id);

  if (juryTotals.length === 0) return { finalScore: null, juryCount: 0, juryTotals };
  const mean = juryTotals.reduce((sum, j) => sum + j.total, 0) / juryTotals.length;
  return { finalScore: round(mean), juryCount: juryTotals.length, juryTotals };
}

/**
 * Calculates every member's final score for a project and stores it in
 * final_results. Allowed only once all assigned jury members have submitted
 * (project status Completed), so a partial result is never stored.
 * @param {number} projectId
 * @param {number} actorUserId the administrator triggering the calculation
 */
async function calculateProjectResults(projectId, actorUserId) {
  return db.withActor(actorUserId, async (client) => {
    const project = await client.query(
      'SELECT project_id, status FROM projects WHERE project_id = $1 FOR UPDATE',
      [projectId]
    );
    if (project.rowCount === 0) throw new HttpError(404, 'Project not found');
    if (!['Completed', 'Finalized'].includes(project.rows[0].status)) {
      throw new HttpError(
        409,
        'Results can be calculated only after all jury members have submitted'
      );
    }

    const criteria = (
      await client.query('SELECT criteria_id, weight::float AS weight FROM criteria')
    ).rows;
    const members = (
      await client.query(
        `SELECT u.user_id AS student_id, u.name
           FROM project_members pm JOIN users u ON u.user_id = pm.student_id
          WHERE pm.project_id = $1 ORDER BY u.name`,
        [projectId]
      )
    ).rows;
    const evaluations = (
      await client.query(
        `SELECT jury_id, student_id, criteria_id, score, is_submitted
           FROM evaluations WHERE project_id = $1`,
        [projectId]
      )
    ).rows;

    const results = [];
    for (const member of members) {
      const own = evaluations.filter((e) => e.student_id === member.student_id);
      const result = calculateStudentScore(own, criteria);
      if (result.finalScore !== null) {
        await client.query(
          `INSERT INTO final_results (project_id, student_id, total_weighted_score)
           VALUES ($1, $2, $3)
           ON CONFLICT (project_id, student_id)
           DO UPDATE SET total_weighted_score = EXCLUDED.total_weighted_score,
                         generated_at = NOW()`,
          [projectId, member.student_id, result.finalScore]
        );
      }
      results.push({ student_id: member.student_id, name: member.name, ...result });
    }
    return { project_id: projectId, results };
  });
}

module.exports = { calculateStudentScore, calculateProjectResults, round };
