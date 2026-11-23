import 'package:material_ui/material_ui.dart';

import '../config/app_theme.dart';
import '../models/project.dart';
import '../services/api_client.dart';
import '../services/app_services.dart';
import '../utils/formatters.dart';
import '../widgets/grading_form.dart';
import '../widgets/status_badge.dart';

/// One project: header, members and the grading form for each member.
class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen(
      {super.key, required this.projectId, required this.title});

  final int projectId;
  final String title;

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  ProjectDetail? _project;
  String? _error;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final project =
          await AppServices.of(context).jury.getProject(widget.projectId);
      if (!mounted) return;
      setState(() {
        _project = project;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _openGrading(StudentEvaluation student) async {
    final project = _project!;
    final updated = await showModalBottomSheet<ProjectDetail>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => GradingForm(project: project, student: student),
    );
    if (updated != null && mounted) {
      setState(() => _project = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.title, overflow: TextOverflow.ellipsis)),
      body: RefreshIndicator(
          color: AppColors.primary, onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final project = _project;
    if (project == null) {
      if (_error == null) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
      }
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 80),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
              child: OutlinedButton(
                  onPressed: _load, child: const Text('Try again'))),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProjectHeader(project: project),
        const SizedBox(height: 16),
        const Text(
          'PROJECT MEMBERS',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
              letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        for (final s in project.students)
          Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor:
                    (s.submitted ? AppColors.success : AppColors.primary)
                        .withAlpha(30),
                child: Icon(
                  s.submitted ? Icons.check : Icons.person_outline,
                  color: s.submitted ? AppColors.success : AppColors.primary,
                ),
              ),
              title: Text(s.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(s.username),
              trailing: StatusBadge.forStudent(
                  submitted: s.submitted, hasScores: s.scores.isNotEmpty),
              onTap: () => _openGrading(s),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Tap a member to enter scores. Drafts can be changed; submitted scores are locked.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project});

  final ProjectDetail project;

  @override
  Widget build(BuildContext context) {
    final total = project.students.length;
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(formatDateTime(project.examDateTime),
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            if (project.advisorName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.school_outlined,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('Advisor: ${project.advisorName}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ],
            if (project.description != null &&
                project.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(project.description!,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
            ],
            const SizedBox(height: 12),
            Text(
              '${project.submittedCount} of $total members submitted',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : project.submittedCount / total,
                minHeight: 5,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.success),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
