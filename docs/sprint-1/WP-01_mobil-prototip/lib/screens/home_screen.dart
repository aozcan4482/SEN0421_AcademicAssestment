import 'package:flutter/material.dart';
import 'package:capstone_evaluationapp/screens/evaluation_screen.dart';

// ---------------------------------------------------------------------------
// Data models — will be replaced by API response objects when backend is ready
// ---------------------------------------------------------------------------

class ProjectMember {
  final String name;
  final String studentId;

  const ProjectMember({required this.name, required this.studentId});
}

class CapstoneProject {
  final String id;
  final String title;
  final String description;
  final String advisor;
  final DateTime examDateTime;
  final List<ProjectMember> members;
  final int evaluatedCount;

  const CapstoneProject({
    required this.id,
    required this.title,
    required this.description,
    required this.advisor,
    required this.examDateTime,
    required this.members,
    required this.evaluatedCount,
  });

  // A project is complete when all members have been evaluated
  bool get isCompleted => evaluatedCount == members.length;
}

// ---------------------------------------------------------------------------
// Mock data — swap with API calls once the backend is connected
// ---------------------------------------------------------------------------

final List<CapstoneProject> mockProjects = [
  CapstoneProject(
    id: '1',
    title: 'AI-Powered Health Monitoring System',
    description:
        'A mobile application that analyzes patient health data using machine learning algorithms and provides early warnings.',
    advisor: 'Prof. Dr. Ahmet Yılmaz',
    examDateTime: DateTime(2025, 6, 10, 10, 0),
    members: const [
      ProjectMember(name: 'Emirhan Çelik', studentId: '2000001042'),
      ProjectMember(name: 'Büşra Kaya', studentId: '2000001078'),
      ProjectMember(name: 'Tarık Arslan', studentId: '2100002031'),
    ],
    evaluatedCount: 1,
  ),
  CapstoneProject(
    id: '2',
    title: 'Smart Campus Navigation App',
    description:
        'A mobile platform that provides indoor navigation using AR technology and displays campus events in real time.',
    advisor: 'Doç. Dr. Fatma Şahin',
    examDateTime: DateTime(2025, 6, 10, 13, 30),
    members: const [
      ProjectMember(name: 'Zeynep Öztürk', studentId: '2100002104'),
      ProjectMember(name: 'Mert Doğan', studentId: '2200003057'),
    ],
    evaluatedCount: 2,
  ),
  CapstoneProject(
    id: '3',
    title: 'Blockchain-Based Diploma Verification',
    description:
        'A distributed system for securely storing and verifying university diplomas on a blockchain network.',
    advisor: 'Dr. Öğr. Üyesi Burak Koç',
    examDateTime: DateTime(2025, 6, 11, 9, 0),
    members: const [
      ProjectMember(name: 'Elif Demir', studentId: '2200003018'),
      ProjectMember(name: 'Oğuzhan Polat', studentId: '2200003145'),
      ProjectMember(name: 'Selin Aydın', studentId: '2300004022'),
      ProjectMember(name: 'Kadir Yıldız', studentId: '2300004089'),
    ],
    evaluatedCount: 0,
  ),
  CapstoneProject(
    id: '4',
    title: 'IoT-Based Energy Management System',
    description:
        'A smart system that monitors and optimizes energy consumption in buildings through sensor networks.',
    advisor: 'Prof. Dr. Hasan Özer',
    examDateTime: DateTime(2025, 6, 11, 14, 0),
    members: const [
      ProjectMember(name: 'Merve Güler', studentId: '2100002198'),
      ProjectMember(name: 'Berkay Kılıç', studentId: '2200003201'),
    ],
    evaluatedCount: 2,
  ),
];

// Past projects shown in the sidebar history list
final List<Map<String, String>> pastProjects = [
  {'title': 'E-Commerce Recommendation Engine', 'date': 'Jan 2025'},
  {'title': 'NLP-Based CV Analyzer', 'date': 'Jan 2025'},
  {'title': 'Drone Fleet Management', 'date': 'Jun 2024'},
  {'title': 'Social Media Analytics Tool', 'date': 'Jan 2024'},
];

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Brand colors
  static const Color ikuRed = Color(0xFFD31018);
  static const Color ikuGrey = Color(0xFF4A4A49);
  static const Color bgColor = Color(0xFFF5F5F7);

  // Tracks which project card is currently expanded
  String? _expandedProjectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      drawer: _buildSidebar(context),
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  // ---------------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.white,
      leading: Builder(
        builder: (ctx) => GestureDetector(
          onTap: () => Scaffold.of(ctx).openDrawer(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: CircleAvatar(
              backgroundColor: ikuRed,
              child: const Text(
                'MK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
      title: const Text(
        'My Evaluations',
        style: TextStyle(
          color: ikuGrey,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Icon(Icons.notifications_outlined, color: ikuGrey),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Body — project list
  // ---------------------------------------------------------------------------

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'ASSIGNED PROJECTS',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ikuGrey,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        ...mockProjects.map((project) => _buildProjectCard(project)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Project card (accordion)
  // ---------------------------------------------------------------------------

  Widget _buildProjectCard(CapstoneProject project) {
    final isExpanded = _expandedProjectId == project.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedProjectId = isExpanded ? null : project.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded ? ikuRed.withOpacity(0.4) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Card header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Status indicator dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: project.isCompleted
                          ? const Color(0xFF2ECC71)
                          : const Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and exam date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ikuGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateTime(project.examDateTime),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status badge and member progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _statusBadge(project.isCompleted),
                      const SizedBox(height: 4),
                      Text(
                        '${project.evaluatedCount}/${project.members.length} members',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: ikuGrey,
                    size: 20,
                  ),
                ],
              ),
            ),

            // Evaluation progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: project.members.isEmpty
                      ? 0
                      : project.evaluatedCount / project.members.length,
                  minHeight: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    project.isCompleted
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFFF6B35),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Expanded detail section
            if (isExpanded) _buildExpandedContent(project),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Expanded card content
  // ---------------------------------------------------------------------------

  Widget _buildExpandedContent(CapstoneProject project) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Short project description
          Text(
            project.description,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
          ),
          const SizedBox(height: 12),

          // Advisor name
          Row(
            children: [
              Icon(Icons.school_outlined, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                'Advisor: ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                project.advisor,
                style: const TextStyle(
                  fontSize: 12,
                  color: ikuGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Member list header
          Text(
            'PROJECT MEMBERS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade400,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          // One row per member
          ...project.members.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: ikuRed.withOpacity(0.1),
                    child: Text(
                      m.name.substring(0, 1),
                      style: const TextStyle(
                        color: ikuRed,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      m.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ikuGrey,
                      ),
                    ),
                  ),
                  Text(
                    m.studentId,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Navigate to the evaluation screen for this project
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EvaluationScreen(project: project),
                  ),
                );
              },
              icon: const Icon(Icons.edit_note, size: 18),
              label: Text(
                project.isCompleted ? 'View Evaluation' : 'Evaluate Members',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: project.isCompleted ? Colors.grey.shade600 : ikuRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Status pill shown on each card
  Widget _statusBadge(bool completed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: completed
            ? const Color(0xFF2ECC71).withOpacity(0.12)
            : const Color(0xFFFF6B35).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        completed ? 'Completed' : 'Pending',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: completed ? const Color(0xFF27AE60) : const Color(0xFFE55A00),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar drawer
  // ---------------------------------------------------------------------------

  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Juror profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: ikuRed,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Text(
                      'MK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Prof. Dr. Mehmet Karaca',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Computer Engineering',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Past evaluations section label
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'PAST EVALUATIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade400,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // Scrollable list of previously evaluated projects
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: pastProjects.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, i) {
                  final p = pastProjects[i];
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ikuRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.folder_outlined, color: ikuRed, size: 18),
                    ),
                    title: Text(
                      p['title']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ikuGrey,
                      ),
                    ),
                    subtitle: Text(
                      p['date']!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                    trailing: Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
                    onTap: () {},
                  );
                },
              ),
            ),

            // Logout — returns to login screen
            Divider(height: 1, color: Colors.grey.shade200),
            ListTile(
              leading: const Icon(Icons.logout, color: ikuRed, size: 20),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: ikuRed,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  // Formats a DateTime into a readable exam schedule string
  String _formatDateTime(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year}  •  $hour:$minute';
  }
}
