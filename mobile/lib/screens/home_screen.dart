import 'package:material_ui/material_ui.dart';

import '../config/app_theme.dart';
import '../models/project.dart';
import '../services/api_client.dart';
import '../services/app_services.dart';
import '../utils/formatters.dart';
import '../widgets/status_badge.dart';
import 'evaluation_screen.dart';
import 'login_screen.dart';

/// The jury member's assigned projects with evaluation progress.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const route = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ProjectSummary>? _projects;
  String? _error;
  bool _loading = false;
  int? _expandedId;
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final projects = await AppServices.of(context).jury.listProjects();
      if (!mounted) return;
      setState(() => _projects = projects);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openProject(ProjectSummary project) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (_) =>
              EvaluationScreen(projectId: project.id, title: project.name)),
    );
    if (mounted) _load(); // progress may have changed
  }

  Future<void> _logout() async {
    await AppServices.of(context).auth.logout();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(LoginScreen.route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = AppServices.of(context).auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Evaluations',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user?.initials ?? '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(user?.name ?? ''),
                subtitle: Text('${user?.role ?? ''} • ${user?.username ?? ''}'),
              ),
              const Divider(),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.primary),
                title: const Text('Sign out'),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_projects == null && _loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null && _projects == null) {
      return _Message(
          icon: Icons.cloud_off,
          text: _error!,
          actionLabel: 'Try again',
          onAction: _load);
    }
    final projects = _projects ?? const <ProjectSummary>[];
    if (projects.isEmpty) {
      return const _Message(
          icon: Icons.inbox_outlined,
          text: 'No projects are assigned to you yet.');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'ASSIGNED PROJECTS',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
              letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        for (final p in projects)
          _ProjectCard(
            project: p,
            expanded: _expandedId == p.id,
            onToggle: () =>
                setState(() => _expandedId = _expandedId == p.id ? null : p.id),
            onEvaluate: () => _openProject(p),
          ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.expanded,
    required this.onToggle,
    required this.onEvaluate,
  });

  final ProjectSummary project;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onEvaluate;

  @override
  Widget build(BuildContext context) {
    final done = project.isCompleted;
    final accent = done ? AppColors.success : AppColors.pending;
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: expanded
                ? AppColors.primary.withAlpha(100)
                : Colors.transparent,
            width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDateTime(project.examDateTime),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(
                          label: done ? 'Completed' : 'Pending', color: accent),
                      const SizedBox(height: 4),
                      Text(
                        '${project.submittedCount}/${project.members.length} members',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.text),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: project.progress,
                  minHeight: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              if (expanded) ...[
                const SizedBox(height: 14),
                if (project.description != null &&
                    project.description!.isNotEmpty) ...[
                  Text(project.description!,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4)),
                  const SizedBox(height: 10),
                ],
                if (project.advisorName != null)
                  Text('Advisor: ${project.advisorName}',
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.text)),
                const SizedBox(height: 10),
                for (final m in project.members)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 16, color: AppColors.text),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(m.name,
                                style: const TextStyle(fontSize: 13))),
                        StatusBadge.forStudent(
                            submitted: m.submitted, hasScores: m.evaluated),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onEvaluate,
                    icon: Icon(
                        done ? Icons.visibility_outlined : Icons.edit_note),
                    label: Text(done ? 'View scores' : 'Evaluate'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(
      {required this.icon,
      required this.text,
      this.actionLabel,
      this.onAction});

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    // A ListView keeps pull-to-refresh working on the empty/error state.
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.text)),
        if (actionLabel != null) ...[
          const SizedBox(height: 16),
          Center(
              child: OutlinedButton(
                  onPressed: onAction, child: Text(actionLabel!))),
        ],
      ],
    );
  }
}
