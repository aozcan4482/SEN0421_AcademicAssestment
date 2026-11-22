'use strict';

jest.mock('../../src/services/auditService', () => ({
  ACTIONS: { ACCESS_DENIED: 'ACCESS_DENIED' },
  record: jest.fn(),
  requestContext: () => ({}),
}));
jest.mock('../../src/repositories/assignmentRepository', () => ({
  isJuryAssigned: jest.fn(),
}));

const jwt = require('jsonwebtoken');
const authenticate = require('../../src/middleware/authenticate');
const { requireRole, requireJuryAssignment } = require('../../src/middleware/authorize');
const auditService = require('../../src/services/auditService');
const assignmentRepository = require('../../src/repositories/assignmentRepository');

const secret = process.env.JWT_SECRET;

function requestWith(header) {
  return { get: (name) => (name === 'Authorization' ? header : undefined), params: {} };
}

afterEach(() => jest.clearAllMocks());

describe('authenticate', () => {
  test('rejects a request without a token', () => {
    const next = jest.fn();
    authenticate(requestWith(undefined), {}, next);
    expect(next.mock.calls[0][0]).toMatchObject({ status: 401 });
  });

  test('rejects a non-Bearer scheme', () => {
    const next = jest.fn();
    authenticate(requestWith('Basic abc'), {}, next);
    expect(next.mock.calls[0][0]).toMatchObject({ status: 401 });
  });

  test('accepts a valid token and exposes the user', () => {
    const token = jwt.sign({ role: 'Jury' }, secret, { subject: '7', expiresIn: '1h' });
    const req = requestWith(`Bearer ${token}`);
    const next = jest.fn();
    authenticate(req, {}, next);
    expect(next).toHaveBeenCalledWith();
    expect(req.user).toEqual({ userId: 7, role: 'Jury' });
  });

  test('rejects an expired token', () => {
    const token = jwt.sign({ role: 'Jury' }, secret, { subject: '7', expiresIn: -10 });
    expect(() => authenticate(requestWith(`Bearer ${token}`), {}, jest.fn())).toThrow(
      'Session expired'
    );
  });

  test('rejects a token signed with another secret', () => {
    const token = jwt.sign({ role: 'Admin' }, 'x'.repeat(40), { subject: '1' });
    expect(() => authenticate(requestWith(`Bearer ${token}`), {}, jest.fn())).toThrow(
      'Invalid token'
    );
  });

  test('rejects a token using the "none" algorithm', () => {
    const forged = jwt.sign({ role: 'Admin' }, null, { subject: '1', algorithm: 'none' });
    expect(() => authenticate(requestWith(`Bearer ${forged}`), {}, jest.fn())).toThrow(
      'Invalid token'
    );
  });
});

describe('requireRole', () => {
  test('lets an allowed role through', () => {
    const next = jest.fn();
    requireRole('Admin')({ user: { userId: 1, role: 'Admin' } }, {}, next);
    expect(next).toHaveBeenCalledWith();
  });

  test('refuses other roles with 403 and audits the refusal', () => {
    const next = jest.fn();
    requireRole('Admin')({ user: { userId: 2, role: 'Jury' } }, {}, next);
    expect(next.mock.calls[0][0]).toMatchObject({ status: 403 });
    expect(auditService.record).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'ACCESS_DENIED', actorUserId: 2 })
    );
  });
});

describe('requireJuryAssignment', () => {
  const req = (projectId) => ({ user: { userId: 5, role: 'Jury' }, params: { projectId } });

  test('lets an assigned jury member through', async () => {
    assignmentRepository.isJuryAssigned.mockResolvedValue(true);
    const r = req('3');
    const next = jest.fn();
    await requireJuryAssignment()(r, {}, next);
    expect(next).toHaveBeenCalledWith();
    expect(r.projectId).toBe(3);
  });

  test('refuses a jury member not assigned to the project', async () => {
    assignmentRepository.isJuryAssigned.mockResolvedValue(false);
    const next = jest.fn();
    await requireJuryAssignment()(req('3'), {}, next);
    expect(next.mock.calls[0][0]).toMatchObject({ status: 403 });
    expect(auditService.record).toHaveBeenCalled();
  });

  test('rejects an invalid project id without querying', async () => {
    const next = jest.fn();
    await requireJuryAssignment()(req('abc'), {}, next);
    expect(next.mock.calls[0][0]).toMatchObject({ status: 400 });
    expect(assignmentRepository.isJuryAssigned).not.toHaveBeenCalled();
  });
});
