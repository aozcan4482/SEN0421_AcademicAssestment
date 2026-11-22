'use strict';

const { calculateStudentScore, round } = require('../../src/services/scoringService');

// The rubric defined in WP-04 (weights sum to 1.0).
const CRITERIA = [
  { criteria_id: 1, weight: 0.15 },
  { criteria_id: 2, weight: 0.4 },
  { criteria_id: 3, weight: 0.15 },
  { criteria_id: 4, weight: 0.1 },
  { criteria_id: 5, weight: 0.1 },
  { criteria_id: 6, weight: 0.1 },
];

/** Builds one jury member's submitted scores, in criteria order. */
function jury(juryId, scores, { submitted = true } = {}) {
  return scores.map((score, i) => ({
    jury_id: juryId,
    criteria_id: i + 1,
    score,
    is_submitted: submitted,
  }));
}

describe('calculateStudentScore', () => {
  test('all scores 100 give 100', () => {
    expect(
      calculateStudentScore(jury(1, [100, 100, 100, 100, 100, 100]), CRITERIA).finalScore
    ).toBe(100);
  });

  test('all scores 0 give 0', () => {
    expect(calculateStudentScore(jury(1, [0, 0, 0, 0, 0, 0]), CRITERIA).finalScore).toBe(0);
  });

  test('applies the criterion weights', () => {
    // 80*.15 + 90*.40 + 70*.15 + 60*.10 + 85*.10 + 75*.10 = 80.5
    const result = calculateStudentScore(jury(1, [80, 90, 70, 60, 85, 75]), CRITERIA);
    expect(result.finalScore).toBe(80.5);
    expect(result.juryTotals).toEqual([{ jury_id: 1, total: 80.5 }]);
  });

  test('the heaviest criterion dominates', () => {
    const onlyDesign = calculateStudentScore(jury(1, [0, 100, 0, 0, 0, 0]), CRITERIA);
    const onlyPapers = calculateStudentScore(jury(1, [0, 0, 0, 0, 0, 100]), CRITERIA);
    expect(onlyDesign.finalScore).toBe(40);
    expect(onlyPapers.finalScore).toBe(10);
  });

  test('averages the totals of several jury members', () => {
    const evaluations = [
      ...jury(1, [80, 90, 70, 60, 85, 75]), // 80.5
      ...jury(2, [60, 70, 50, 40, 65, 55]), // 60.5
    ];
    const result = calculateStudentScore(evaluations, CRITERIA);
    expect(result.juryCount).toBe(2);
    expect(result.finalScore).toBe(70.5);
  });

  test('ignores draft (not submitted) scores', () => {
    const evaluations = [
      ...jury(1, [80, 90, 70, 60, 85, 75]),
      ...jury(2, [0, 0, 0, 0, 0, 0], { submitted: false }),
    ];
    const result = calculateStudentScore(evaluations, CRITERIA);
    expect(result.juryCount).toBe(1);
    expect(result.finalScore).toBe(80.5);
  });

  test('ignores a jury member who has not scored every criterion', () => {
    const evaluations = [...jury(1, [80, 90, 70, 60, 85, 75]), ...jury(2, [10, 10, 10])];
    expect(calculateStudentScore(evaluations, CRITERIA).juryCount).toBe(1);
  });

  test('returns null when no jury member has a complete submitted set', () => {
    const result = calculateStudentScore(jury(1, [80, 90]), CRITERIA);
    expect(result).toEqual({ finalScore: null, juryCount: 0, juryTotals: [] });
  });

  test('returns null for a student with no evaluations', () => {
    expect(calculateStudentScore([], CRITERIA).finalScore).toBeNull();
  });

  test('ignores scores for criteria that are not in the rubric', () => {
    const evaluations = [
      ...jury(1, [80, 90, 70, 60, 85, 75]),
      { jury_id: 1, criteria_id: 99, score: 0, is_submitted: true },
    ];
    expect(calculateStudentScore(evaluations, CRITERIA).finalScore).toBe(80.5);
  });

  test('rounds the final score to two decimals', () => {
    const evaluations = [
      ...jury(1, [81, 81, 81, 81, 81, 81]), // 81
      ...jury(2, [80, 80, 80, 80, 80, 80]), // 80
      ...jury(3, [80, 80, 80, 80, 80, 80]), // 80 -> mean 80.333...
    ];
    expect(calculateStudentScore(evaluations, CRITERIA).finalScore).toBe(80.33);
  });

  test('accepts weights returned as strings by the database driver', () => {
    const asStrings = CRITERIA.map((c) => ({ ...c, weight: String(c.weight) }));
    expect(calculateStudentScore(jury(1, [80, 90, 70, 60, 85, 75]), asStrings).finalScore).toBe(
      80.5
    );
  });

  test('throws when the rubric is empty', () => {
    expect(() => calculateStudentScore([], [])).toThrow('At least one criterion is required');
  });
});

describe('round', () => {
  test.each([
    [80.333, 80.33],
    [80.335, 80.34],
    [1.005, 1.01],
    [70, 70],
  ])('round(%p) = %p', (input, expected) => {
    expect(round(input)).toBe(expected);
  });
});
