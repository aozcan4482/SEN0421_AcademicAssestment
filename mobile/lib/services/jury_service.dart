import '../models/project.dart';
import 'api_client.dart';

/// A score entered on the grading form, before it is sent to the server.
class ScoreInput {
  const ScoreInput(
      {required this.criterionId, required this.value, this.comment});

  final int criterionId;
  final int value;
  final String? comment;

  Map<String, dynamic> toJson() => {
        'criteria_id': criterionId,
        'score': value,
        if (comment != null && comment!.trim().isNotEmpty)
          'comment': comment!.trim(),
      };
}

/// Jury member operations: assigned projects and score entry.
class JuryService {
  JuryService(this._api);

  final ApiClient _api;

  Future<List<ProjectSummary>> listProjects() async {
    final json = await _api.get('/jury/projects') as List<dynamic>;
    return json
        .map((p) => ProjectSummary.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectDetail> getProject(int projectId) async {
    final json =
        await _api.get('/jury/projects/$projectId') as Map<String, dynamic>;
    return ProjectDetail.fromJson(json);
  }

  /// Saves a student's scores as a draft, or submits them when [submit] is
  /// true. Submitted scores are locked on the server. Returns the updated
  /// project.
  Future<ProjectDetail> saveEvaluation({
    required int projectId,
    required int studentId,
    required List<ScoreInput> scores,
    required bool submit,
  }) async {
    final json = await _api.put(
      '/jury/projects/$projectId/students/$studentId/evaluation',
      {'scores': scores.map((s) => s.toJson()).toList(), 'submit': submit},
    ) as Map<String, dynamic>;
    return ProjectDetail.fromJson(json);
  }
}
