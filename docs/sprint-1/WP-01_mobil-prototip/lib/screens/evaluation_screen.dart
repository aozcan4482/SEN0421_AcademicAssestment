import 'package:flutter/material.dart';
import 'package:capstone_evaluationapp/screens/home_screen.dart';

// ---------------------------------------------------------------------------
// EvaluationScreen — opened when juror taps "Evaluate Members" or
// "View Evaluation" on a project card in HomeScreen
// ---------------------------------------------------------------------------

class EvaluationScreen extends StatefulWidget {
  final CapstoneProject project;

  const EvaluationScreen({super.key, required this.project});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  // Brand colors
  static const Color ikuRed = Color(0xFFD31018);
  static const Color ikuGrey = Color(0xFF4A4A49);
  static const Color bgColor = Color(0xFFF5F5F7);

  // Tracks which member card is expanded
  String? _expandedMemberId;

  // Tracks which member is in grading mode (score input visible)
  String? _gradingMemberId;

  // Stores confirmed (submitted) scores per member
  // Map<studentId, Map<criterionLabel, score>>
  final Map<String, Map<String, double?>> _confirmedScores = {};

  // Grading criteria shown for every member
  static const List<String> _criteria = [
    'Technical Merits',
    'Project Design & Implementation',
    'Report',
    'Presentation',
    'Demo',
    'Papers',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
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
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: ikuGrey),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Evaluation',
        style: TextStyle(
          color: ikuGrey,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProjectHeader(),
        const SizedBox(height: 20),
        Text(
          'STUDENTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade400,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        ...widget.project.members.map((m) => _buildMemberCard(m)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Project info header card
  // ---------------------------------------------------------------------------

  Widget _buildProjectHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project title with accent bar
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: ikuRed,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.project.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ikuGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Project description
          Text(
            widget.project.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),

          // Advisor row
          Row(
            children: [
              Icon(Icons.school_outlined, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                'Advisor: ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.project.advisor,
                style: const TextStyle(
                  fontSize: 12,
                  color: ikuGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Exam date row
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                _formatDateTime(widget.project.examDateTime),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Member accordion card
  // ---------------------------------------------------------------------------

  Widget _buildMemberCard(ProjectMember member) {
    final isExpanded = _expandedMemberId == member.studentId;
    final isGrading = _gradingMemberId == member.studentId;
    final isEvaluated = _confirmedScores.containsKey(member.studentId);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedMemberId = null;
            _gradingMemberId = null;
          } else {
            _expandedMemberId = member.studentId;
            _gradingMemberId = null;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded ? ikuRed.withOpacity(0.35) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Member header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Avatar with initial
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: ikuRed.withOpacity(0.1),
                    child: Text(
                      member.name.substring(0, 1),
                      style: const TextStyle(
                        color: ikuRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and student ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ikuGrey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          member.studentId,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Evaluated badge or chevron
                  if (isEvaluated)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Graded',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                    )
                  else
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: ikuGrey,
                      size: 20,
                    ),
                ],
              ),
            ),

            // Expanded: either summary of confirmed scores or grading form
            if (isExpanded) ...[
              if (isGrading)
                _buildGradingForm(member)
              else
                _buildMemberActions(member, isEvaluated),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action row shown when a member card is expanded but not yet in grading mode
  // ---------------------------------------------------------------------------

  Widget _buildMemberActions(ProjectMember member, bool isEvaluated) {
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
          // Show previously confirmed scores if available
          if (isEvaluated) ...[
            Text(
              'SCORES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade400,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            ..._confirmedScores[member.studentId]!.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.key,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                    Text(
                      e.value != null ? e.value!.toStringAsFixed(1) : '—',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ikuGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Grade / Re-grade button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _gradingMemberId = member.studentId;
                });
              },
              icon: Icon(
                isEvaluated ? Icons.edit : Icons.grade_outlined,
                size: 17,
              ),
              label: Text(isEvaluated ? 'Edit Grades' : 'Grade Student'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEvaluated ? Colors.grey.shade600 : ikuRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Grading form — score inputs for all criteria
  // ---------------------------------------------------------------------------

  Widget _buildGradingForm(ProjectMember member) {
    // Local state for this form held in a StatefulBuilder so the rest of the
    // tree does not rebuild on every keystroke
    final Map<String, TextEditingController> controllers = {
      for (final c in _criteria)
        c: TextEditingController(
          text: _confirmedScores[member.studentId]?[c]?.toString() ?? '',
        ),
    };
    bool confirmed = false;

    return StatefulBuilder(
      builder: (context, setLocal) {
        return GestureDetector(
          // Prevent taps inside the form from toggling the parent accordion
          onTap: () {},
          child: Container(
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
                Text(
                  'ENTER SCORES  (0 – 100)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade400,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),

                // One text field per criterion
                ..._criteria.map(
                  (criterion) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: controllers[criterion],
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: criterion,
                        filled: true,
                        fillColor: Colors.white,
                        suffixText: 'pts',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Confirmation checkbox
                GestureDetector(
                  onTap: () => setLocal(() => confirmed = !confirmed),
                  child: Row(
                    children: [
                      Checkbox(
                        value: confirmed,
                        activeColor: ikuRed,
                        onChanged: (v) =>
                            setLocal(() => confirmed = v ?? false),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'I confirm that the scores above are final.',
                          style: TextStyle(fontSize: 13, color: ikuGrey),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Submit and cancel buttons
                Row(
                  children: [
                    // Cancel — go back to action view
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _gradingMemberId = null);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ikuGrey,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Complete — saves scores and collapses the form
                    Expanded(
                      child: ElevatedButton(
                        onPressed: confirmed
                            ? () {
                                // Parse and store each criterion score
                                final scores = <String, double?>{};
                                for (final c in _criteria) {
                                  final raw = controllers[c]!.text.trim();
                                  scores[c] = raw.isEmpty
                                      ? null
                                      : double.tryParse(raw);
                                }
                                setState(() {
                                  _confirmedScores[member.studentId] = scores;
                                  _gradingMemberId = null;
                                  _expandedMemberId = null;
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ikuRed,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        child: const Text('Complete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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
