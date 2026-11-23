import 'package:academic_assessment/models/project.dart';
import 'package:academic_assessment/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

// Payloads in the exact shape returned by the API.
const _userJson = {
  'user_id': 2,
  'username': 'jury.demo1',
  'name': 'Demo Jury One',
  'email': 'jury1@example.edu',
  'role': 'Jury',
};

const _summaryJson = {
  'project_id': 1,
  'project_name': 'Smart Campus Navigation',
  'description': 'Indoor navigation app for the campus (team project).',
  'exam_datetime': '2026-12-15T07:00:00.000Z',
  'status': 'In Progress',
  'advisor_name': 'Demo Jury One',
  'is_completed': false,
  'completed_at': null,
  'members': [
    {
      'student_id': 4,
      'name': 'Demo Student One',
      'username': 'student.d1',
      'evaluated': true,
      'submitted': true
    },
    {
      'student_id': 5,
      'name': 'Demo Student Two',
      'username': 'student.d2',
      'evaluated': false,
      'submitted': false
    },
  ],
  'member_count': 2,
  'evaluated_count': 1,
};

const _detailJson = {
  'project_id': 1,
  'project_name': 'Smart Campus Navigation',
  'description': null,
  'exam_datetime': null,
  'status': 'In Progress',
  'advisor_name': null,
  'criteria': [
    {'criteria_id': 1, 'criteria_name': 'Technical Merits', 'weight': 0.15},
    {
      'criteria_id': 2,
      'criteria_name': 'Project Design and Implementation',
      'weight': 0.4
    },
    {'criteria_id': 3, 'criteria_name': 'Whole', 'weight': 1},
  ],
  'students': [
    {
      'student_id': 4,
      'name': 'Demo Student One',
      'username': 'student.d1',
      'scores': [
        {'criteria_id': 1, 'score': 80, 'comment': 'Clear design'},
      ],
      'evaluated': false,
      'submitted': false,
    },
    {
      'student_id': 5,
      'name': 'Demo Student Two',
      'username': 'student.d2',
      'scores': [],
      'evaluated': false,
      'submitted': false
    },
  ],
};

void main() {
  group('AppUser', () {
    test('parses the login user', () {
      final user = AppUser.fromJson(_userJson);
      expect(user.id, 2);
      expect(user.isJury, isTrue);
      expect(user.initials, 'DJ');
    });

    test('initials handle a single name', () {
      final user = AppUser.fromJson({..._userJson, 'name': 'admin'});
      expect(user.initials, 'A');
    });
  });

  group('ProjectSummary', () {
    test('parses members and progress', () {
      final p = ProjectSummary.fromJson(_summaryJson);
      expect(p.id, 1);
      expect(p.members, hasLength(2));
      expect(p.submittedCount, 1);
      expect(p.progress, 0.5);
      expect(p.examDateTime, isNotNull);
      expect(p.examDateTime!.isUtc, isFalse); // converted to local time
    });

    test('progress is 0 when the project has no members', () {
      final p =
          ProjectSummary.fromJson({..._summaryJson, 'members': <dynamic>[]});
      expect(p.progress, 0);
    });
  });

  group('ProjectDetail', () {
    test('parses criteria, students and scores', () {
      final d = ProjectDetail.fromJson(_detailJson);
      expect(d.criteria.map((c) => c.id), [1, 2, 3]);
      expect(d.criteria[1].weight, 0.4);
      expect(d.criteria[2].weight, 1.0); // integer weight from JSON
      expect(d.students.first.scoreFor(1)?.value, 80);
      expect(d.students.first.scoreFor(1)?.comment, 'Clear design');
      expect(d.students.first.scoreFor(2), isNull);
      expect(d.examDateTime, isNull);
    });

    test('weight label is a percentage', () {
      final d = ProjectDetail.fromJson(_detailJson);
      expect(d.criteria[1].weightLabel, '40%');
    });
  });
}
