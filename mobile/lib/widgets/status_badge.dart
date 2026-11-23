import 'package:material_ui/material_ui.dart';

import '../config/app_theme.dart';

/// Small coloured pill showing a state such as "Submitted" or "Draft".
class StatusBadge extends StatelessWidget {
  const StatusBadge(
      {super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  factory StatusBadge.forStudent(
      {required bool submitted, required bool hasScores}) {
    if (submitted) {
      return const StatusBadge(
          label: 'Submitted',
          color: AppColors.success,
          icon: Icons.lock_outline);
    }
    if (hasScores) {
      return const StatusBadge(
          label: 'Draft', color: AppColors.pending, icon: Icons.edit_outlined);
    }
    return const StatusBadge(label: 'Not started', color: AppColors.locked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
