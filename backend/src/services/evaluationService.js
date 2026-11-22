'use strict';

/**
 * Score entry rules for jury members.
 *
 *  - Each student of a team is scored individually on every criterion (RSK-01).
 *  - Scores are whole numbers from 0 to 100; a comment is optional.
 *  - Scores can be saved as a draft any number of times. Submitting requires
 *    a score for every criterion; after submission the student's scores can
 *    no longer be changed by the jury member.
 *  - Every change runs as the authenticated user, so the database audit
 *    trigger records who changed what.
 */
const db = require('../db/pool');
const criteriaRepository = require('../repositories/criteriaRepository');
const juryRepository = require('../repositories/juryRepository');
const evaluationRepository = require('../repositories/evaluationRepository');
const HttpError = require('../utils/HttpError');

const MAX_COMMENT_LENGTH = 1000;

function validateScores(input, criteria) {
  if (!Array.isArray(input) || input.length === 0) {
    throw new HttpError(400, 'scores must be a non-empty array');
  }
  const validIds = new Set(criteria.map((c) => c.criteria_id));
  const seen = new Set();

  return input.map((item, i) => {
    const where = `scores[${i}]`;
    const criteriaId = item?.criteria_id;
    const score = item?.score;
    const comment = item?.comment ?? null;

    if (!Number.isInteger(criteriaId) || !validIds.has(criteriaId)) {
      throw new HttpError(400, `${where}.criteria_id is not a valid criterion`);
    }
    if (seen.has(criteriaId)) {
      throw new HttpError(400, `${where}.criteria_id appears more than once`);
    }
    seen.add(criteriaId);
    if (!Number.isInteger(score) || score < 0 || score > 100) {
      throw new HttpError(400, `${where}.score must be a whole number between 0 and 100`);
    }
    if (comment !== null && (typeof comment !== 'string' || comment.length > MAX_COMMENT_LENGTH)) {
      throw new HttpError(
        400,
        `${where}.comment must be text of at most ${MAX_COMMENT_LENGTH} characters`
      );
    }
    return { criteriaId, score, comment: comment === null ? null : comment.trim() || null };
  });
}

/** Assigned projects of a jury member with member progress. */
function listAssignedProjects(juryId) {
  return juryRepository.findAssignedProjects(juryId).then((projects) =>
    projects.map((p) => ({
      ...p,
      member_count: p.members.length,
      evaluated_count: p.members.filter((m) => m.submitted).length,
    }))
  );
}

/** Project detail with the criteria and the jury member's own scores per student. */
async function getProjectForJury(juryId, projectId) {
  const [project, members, criteria, scores] = await Promise.all([
    juryRepository.findProject(projectId),
    juryRepository.findMembers(projectId),
    criteriaRepository.findAll(),
    juryRepository.findOwnScores(juryId, projectId),
  ]);
  if (!project) throw new HttpError(404, 'Project not found');

  const students = members.map((member) => {
    const own = scores.filter((s) => s.student_id === member.student_id);
    return {
      ...member,
      scores: own.map((s) => ({
        criteria_id: s.criteria_id,
        score: s.score,
        comment: s.comment,
      })),
      evaluated: own.length === criteria.length,
      submitted: own.length === criteria.length && own.every((s) => s.is_submitted),
    };
  });
  return { ...project, criteria, students };
}

/**
 * Saves (and optionally submits) one student's scores.
 * @param {{ scores: Array, submit?: boolean }} body
 */
async function saveStudentEvaluation(juryId, projectId, studentId, body) {
  if (!Number.isInteger(studentId) || studentId <= 0) {
    throw new HttpError(400, 'Invalid student id');
  }
  const submit = body?.submit === true;
  const criteria = await criteriaRepository.findAll();
  const scores = validateScores(body?.scores, criteria);

  await db.withActor(juryId, async (client) => {
    if (!(await evaluationRepository.isProjectMember(client, projectId, studentId))) {
      throw new HttpError(404, 'Student is not a member of this project');
    }

    const existing = await evaluationRepository.lockStudentRows(
      client,
      juryId,
      projectId,
      studentId
    );
    if (existing.some((row) => row.is_submitted)) {
      throw new HttpError(
        409,
        'Scores for this student have already been submitted and are locked'
      );
    }

    if (submit) {
      const covered = new Set([
        ...existing.map((row) => row.criteria_id),
        ...scores.map((s) => s.criteriaId),
      ]);
      const missing = criteria.filter((c) => !covered.has(c.criteria_id));
      if (missing.length > 0) {
        throw new HttpError(
          400,
          `Cannot submit: missing scores for ${missing.map((c) => c.criteria_name).join(', ')}`
        );
      }
    }

    for (const s of scores) {
      await evaluationRepository.upsertScore(client, { juryId, projectId, studentId, ...s });
    }
    if (submit) {
      await evaluationRepository.markSubmitted(client, juryId, projectId, studentId);
    }
    await evaluationRepository.refreshProgress(client, juryId, projectId);
  });

  return getProjectForJury(juryId, projectId);
}

module.exports = { listAssignedProjects, getProjectForJury, saveStudentEvaluation };
