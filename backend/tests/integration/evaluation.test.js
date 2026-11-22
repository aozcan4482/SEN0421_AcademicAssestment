'use strict';

const request = require('supertest');
const { createApp } = require('../../src/app');
const { pool } = require('../../src/db/pool');
const { createScenario } = require('../helpers/fixtures');

const app = createApp();
let s;
const tokens = {};

async function tokenFor(user, password) {
  const res = await request(app)
    .post('/api/auth/login')
    .send({ username: user.username, password });
  return res.body.token;
}

function fullScores(criteriaIds, base) {
  return criteriaIds.map((id, i) => ({ criteria_id: id, score: base + i }));
}

const put = (token, projectId, studentId, body) =>
  request(app)
    .put(`/api/jury/projects/${projectId}/students/${studentId}/evaluation`)
    .set('Authorization', `Bearer ${token}`)
    .send(body);

beforeAll(async () => {
  s = await createScenario();
  tokens.jury1 = await tokenFor(s.users.jury1, s.passwords.cats);
  tokens.jury2 = await tokenFor(s.users.jury2, s.passwords.cats);
  tokens.outsider = await tokenFor(s.users.outsider, s.passwords.cats);
  tokens.admin = await tokenFor(s.users.admin, s.passwords.admin);
});
afterAll(async () => {
  await s.cleanup();
  await pool.end();
});

describe('jury project access', () => {
  test('lists only the projects assigned to the jury member', async () => {
    const res = await request(app)
      .get('/api/jury/projects')
      .set('Authorization', `Bearer ${tokens.jury1}`);
    expect(res.status).toBe(200);
    const mine = res.body.find((p) => p.project_id === s.projectId);
    expect(mine).toMatchObject({ member_count: 2, evaluated_count: 0 });

    const other = await request(app)
      .get('/api/jury/projects')
      .set('Authorization', `Bearer ${tokens.outsider}`);
    expect(other.body.find((p) => p.project_id === s.projectId)).toBeUndefined();
  });

  test('an unassigned jury member gets 403 for the project', async () => {
    const res = await request(app)
      .get(`/api/jury/projects/${s.projectId}`)
      .set('Authorization', `Bearer ${tokens.outsider}`);
    expect(res.status).toBe(403);
  });

  test('an unassigned jury member cannot enter scores', async () => {
    const res = await put(tokens.outsider, s.projectId, s.users.student1.id, {
      scores: fullScores(s.criteriaIds, 50),
    });
    expect(res.status).toBe(403);
  });
});

describe('score entry', () => {
  const student = () => s.users.student1.id;

  test('rejects a score above 100', async () => {
    const res = await put(tokens.jury1, s.projectId, student(), {
      scores: [{ criteria_id: s.criteriaIds[0], score: 101 }],
    });
    expect(res.status).toBe(400);
  });

  test('rejects a non-integer score', async () => {
    const res = await put(tokens.jury1, s.projectId, student(), {
      scores: [{ criteria_id: s.criteriaIds[0], score: 75.5 }],
    });
    expect(res.status).toBe(400);
  });

  test('rejects a student who is not a member of the project', async () => {
    const res = await put(tokens.jury1, s.projectId, s.users.otherStudent.id, {
      scores: [{ criteria_id: s.criteriaIds[0], score: 70 }],
    });
    expect(res.status).toBe(404);
  });

  test('saves a draft', async () => {
    const res = await put(tokens.jury1, s.projectId, student(), {
      scores: [{ criteria_id: s.criteriaIds[0], score: 70, comment: 'Draft' }],
    });
    expect(res.status).toBe(200);
    const me = res.body.students.find((st) => st.student_id === student());
    expect(me.scores).toEqual([{ criteria_id: s.criteriaIds[0], score: 70, comment: 'Draft' }]);
    expect(me.submitted).toBe(false);
  });

  test('refuses to submit while a criterion is missing', async () => {
    const res = await put(tokens.jury1, s.projectId, student(), {
      scores: [{ criteria_id: s.criteriaIds[1], score: 80 }],
      submit: true,
    });
    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/missing scores/);
  });

  test('submits a complete set', async () => {
    const res = await put(tokens.jury1, s.projectId, student(), {
      scores: fullScores(s.criteriaIds, 70),
      submit: true,
    });
    expect(res.status).toBe(200);
    expect(res.body.students.find((st) => st.student_id === student()).submitted).toBe(true);
    expect(res.body.status).toBe('In Progress');
  });

  test('submitted scores are locked', async () => {
    const res = await put(tokens.jury1, s.projectId, student(), {
      scores: [{ criteria_id: s.criteriaIds[0], score: 10 }],
    });
    expect(res.status).toBe(409);
  });

  test('another jury member does not see these scores', async () => {
    const res = await request(app)
      .get(`/api/jury/projects/${s.projectId}`)
      .set('Authorization', `Bearer ${tokens.jury2}`);
    expect(res.body.students.every((st) => st.scores.length === 0)).toBe(true);
  });
});

describe('audit trail and final results', () => {
  test('score changes were logged with the jury member as actor', async () => {
    const { rows } = await pool.query(
      `SELECT action, actor_user_id FROM audit_log
        WHERE entity_type = 'evaluation' AND project_id = $1`,
      [s.projectId]
    );
    expect(rows.length).toBeGreaterThan(0);
    expect(rows.every((r) => r.actor_user_id === s.users.jury1.id)).toBe(true);
    expect(rows.map((r) => r.action)).toEqual(
      expect.arrayContaining(['EVALUATION_CREATE', 'EVALUATION_UPDATE', 'EVALUATION_SUBMIT'])
    );
  });

  test('the audit log cannot be modified', async () => {
    await expect(pool.query("UPDATE audit_log SET action = 'LOGIN_SUCCESS'")).rejects.toThrow(
      /append-only/
    );
    await expect(pool.query('DELETE FROM audit_log')).rejects.toThrow(/append-only/);
  });

  test('the audit hash chain is intact', async () => {
    const res = await request(app)
      .get('/api/admin/audit-log/verify')
      .set('Authorization', `Bearer ${tokens.admin}`);
    expect(res.status).toBe(200);
    expect(res.body.intact).toBe(true);
  });

  test('results cannot be calculated before every jury member submits', async () => {
    const res = await request(app)
      .post(`/api/admin/projects/${s.projectId}/results`)
      .set('Authorization', `Bearer ${tokens.admin}`);
    expect(res.status).toBe(409);
  });

  test('after all submissions the weighted final scores are stored', async () => {
    await put(tokens.jury1, s.projectId, s.users.student2.id, {
      scores: fullScores(s.criteriaIds, 60),
      submit: true,
    });
    for (const st of [s.users.student1, s.users.student2]) {
      const r = await put(tokens.jury2, s.projectId, st.id, {
        scores: fullScores(s.criteriaIds, 80),
        submit: true,
      });
      expect(r.status).toBe(200);
    }

    const res = await request(app)
      .post(`/api/admin/projects/${s.projectId}/results`)
      .set('Authorization', `Bearer ${tokens.admin}`);
    expect(res.status).toBe(200);
    expect(res.body.results).toHaveLength(2);
    for (const r of res.body.results) {
      expect(r.juryCount).toBe(2);
      expect(r.finalScore).toBeGreaterThan(0);
      expect(r.finalScore).toBeLessThanOrEqual(100);
    }

    const stored = await pool.query(
      'SELECT count(*)::int AS n FROM final_results WHERE project_id = $1',
      [s.projectId]
    );
    expect(stored.rows[0].n).toBe(2);
  });
});
