/// Data models for the jury member's projects. They mirror the JSON returned
/// by the /api/jury endpoints.
library;

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

/// A student in the project list, with this jury member's progress.
class MemberProgress {
  const MemberProgress({
    required this.studentId,
    required this.name,
    required this.username,
    required this.evaluated,
    required this.submitted,
  });

  final int studentId;
  final String name;
  final String username;
  final bool evaluated;
  final bool submitted;

  factory MemberProgress.fromJson(Map<String, dynamic> json) {
    return MemberProgress(
      studentId: json['student_id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      evaluated: json['evaluated'] as bool? ?? false,
      submitted: json['submitted'] as bool? ?? false,
    );
  }
}

/// One entry of GET /api/jury/projects.
class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.members,
    required this.isCompleted,
    this.description,
    this.advisorName,
    this.examDateTime,
  });

  final int id;
  final String name;
  final String status;
  final List<MemberProgress> members;
  final bool isCompleted;
  final String? description;
  final String? advisorName;
  final DateTime? examDateTime;

  int get submittedCount => members.where((m) => m.submitted).length;

  double get progress => members.isEmpty ? 0 : submittedCount / members.length;

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      id: json['project_id'] as int,
      name: json['project_name'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      advisorName: json['advisor_name'] as String?,
      examDateTime: _parseDate(json['exam_datetime']),
      isCompleted: json['is_completed'] as bool? ?? false,
      members: (json['members'] as List<dynamic>? ?? const [])
          .map((m) => MemberProgress.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// An evaluation criterion and its weight (weights sum to 1.0).
class Criterion {
  const Criterion({required this.id, required this.name, required this.weight});

  final int id;
  final String name;
  final double weight;

  /// Weight as a percentage label, e.g. 0.4 -> "40%".
  String get weightLabel => '${(weight * 100).round()}%';

  factory Criterion.fromJson(Map<String, dynamic> json) {
    return Criterion(
      id: json['criteria_id'] as int,
      name: json['criteria_name'] as String,
      weight: (json['weight'] as num).toDouble(),
    );
  }
}

/// A score this jury member gave for one criterion.
class Score {
  const Score({required this.criterionId, required this.value, this.comment});

  final int criterionId;
  final int value;
  final String? comment;

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      criterionId: json['criteria_id'] as int,
      value: json['score'] as int,
      comment: json['comment'] as String?,
    );
  }
}

/// A student in the project detail, with this jury member's own scores.
class StudentEvaluation {
  const StudentEvaluation({
    required this.studentId,
    required this.name,
    required this.username,
    required this.scores,
    required this.evaluated,
    required this.submitted,
  });

  final int studentId;
  final String name;
  final String username;
  final List<Score> scores;
  final bool evaluated;
  final bool submitted;

  Score? scoreFor(int criterionId) {
    for (final s in scores) {
      if (s.criterionId == criterionId) return s;
    }
    return null;
  }

  factory StudentEvaluation.fromJson(Map<String, dynamic> json) {
    return StudentEvaluation(
      studentId: json['student_id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      evaluated: json['evaluated'] as bool? ?? false,
      submitted: json['submitted'] as bool? ?? false,
      scores: (json['scores'] as List<dynamic>? ?? const [])
          .map((s) => Score.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// GET /api/jury/projects/:id (also returned after saving scores).
class ProjectDetail {
  const ProjectDetail({
    required this.id,
    required this.name,
    required this.status,
    required this.criteria,
    required this.students,
    this.description,
    this.advisorName,
    this.examDateTime,
  });

  final int id;
  final String name;
  final String status;
  final List<Criterion> criteria;
  final List<StudentEvaluation> students;
  final String? description;
  final String? advisorName;
  final DateTime? examDateTime;

  int get submittedCount => students.where((s) => s.submitted).length;

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    return ProjectDetail(
      id: json['project_id'] as int,
      name: json['project_name'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      advisorName: json['advisor_name'] as String?,
      examDateTime: _parseDate(json['exam_datetime']),
      criteria: (json['criteria'] as List<dynamic>? ?? const [])
          .map((c) => Criterion.fromJson(c as Map<String, dynamic>))
          .toList(),
      students: (json['students'] as List<dynamic>? ?? const [])
          .map((s) => StudentEvaluation.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
