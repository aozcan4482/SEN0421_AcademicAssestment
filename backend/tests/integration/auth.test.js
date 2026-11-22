'use strict';

const request = require('supertest');
const { createApp } = require('../../src/app');
const { pool } = require('../../src/db/pool');
const { createScenario } = require('../helpers/fixtures');

const app = createApp();
let s;

beforeAll(async () => {
  s = await createScenario();
});
afterAll(async () => {
  await s.cleanup();
  await pool.end();
});

const login = (username, password) =>
  request(app).post('/api/auth/login').send({ username, password });

describe('POST /api/auth/login', () => {
  test('admin signs in with the local password', async () => {
    const res = await login(s.users.admin.username, s.passwords.admin);
    expect(res.status).toBe(200);
    expect(res.body.token).toEqual(expect.any(String));
    expect(res.body.user).toMatchObject({ role: 'Admin', username: s.users.admin.username });
    expect(res.body.user).not.toHaveProperty('password_hash');
  });

  test('admin with a wrong password gets 401', async () => {
    const res = await login(s.users.admin.username, 'wrong-password');
    expect(res.status).toBe(401);
    expect(res.body.error).toBe('Invalid username or password');
  });

  test('registered jury member signs in through CATS', async () => {
    const res = await login(s.users.jury1.username, s.passwords.cats);
    expect(res.status).toBe(200);
    expect(res.body.user.role).toBe('Jury');
  });

  test('wrong CATS password gets the same generic 401', async () => {
    const res = await login(s.users.jury1.username, 'not-the-password');
    expect(res.status).toBe(401);
    expect(res.body.error).toBe('Invalid username or password');
  });

  test('valid CATS user who is not registered gets 403', async () => {
    const res = await login(`${s.tag}.unknown`, s.passwords.cats);
    expect(res.status).toBe(403);
  });

  test('missing fields get 400', async () => {
    const res = await request(app).post('/api/auth/login').send({ username: 'x' });
    expect(res.status).toBe(400);
  });

  test('every outcome is written to the audit log without the password', async () => {
    const { rows } = await pool.query(
      `SELECT action, details FROM audit_log
        WHERE details->>'username' LIKE $1 ORDER BY audit_id`,
      [`${s.tag}.%`]
    );
    const actions = rows.map((r) => r.action);
    expect(actions).toContain('LOGIN_SUCCESS');
    expect(actions).toContain('LOGIN_FAILURE');
    const serialised = JSON.stringify(rows);
    expect(serialised).not.toContain(s.passwords.admin);
    expect(serialised).not.toContain(s.passwords.cats);
  });
});

describe('GET /api/auth/me', () => {
  test('returns the profile for a valid token', async () => {
    const { body } = await login(s.users.student1.username, s.passwords.cats);
    const res = await request(app).get('/api/auth/me').set('Authorization', `Bearer ${body.token}`);
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ user_id: s.users.student1.id, role: 'Student' });
  });

  test('rejects a request without a token', async () => {
    expect((await request(app).get('/api/auth/me')).status).toBe(401);
  });
});

describe('role-based access', () => {
  test('a jury member cannot open admin routes', async () => {
    const { body } = await login(s.users.jury1.username, s.passwords.cats);
    const res = await request(app)
      .get('/api/admin/audit-log/verify')
      .set('Authorization', `Bearer ${body.token}`);
    expect(res.status).toBe(403);
  });

  test('a student cannot open jury routes', async () => {
    const { body } = await login(s.users.student1.username, s.passwords.cats);
    const res = await request(app)
      .get('/api/jury/projects')
      .set('Authorization', `Bearer ${body.token}`);
    expect(res.status).toBe(403);
  });
});
