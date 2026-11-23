import 'package:material_ui/material_ui.dart';

import '../config/app_theme.dart';
import '../models/project.dart';
import '../services/api_client.dart';
import '../services/app_services.dart';
import '../services/jury_service.dart';
import '../utils/formatters.dart';

/// Score entry for one student, shown in a bottom sheet.
///
/// * "Save draft" stores whatever has been filled in; it can be changed later.
/// * "Submit" requires every criterion, an explicit confirmation and a final
///   dialog, because submitted scores are locked on the server.
/// * Already submitted scores are shown read-only.
///
/// Closes with the updated [ProjectDetail] after a successful save.
class GradingForm extends StatefulWidget {
  const GradingForm({super.key, required this.project, required this.student});

  final ProjectDetail project;
  final StudentEvaluation student;

  @override
  State<GradingForm> createState() => _GradingFormState();
}

class _GradingFormState extends State<GradingForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, TextEditingController> _scores = {};
  final Map<int, TextEditingController> _comments = {};
  final Set<int> _commentOpen = {};
  bool _confirmed = false;
  bool _saving = false;
  bool _submitAttempted = false;
  String? _error;

  bool get _locked => widget.student.submitted;

  @override
  void initState() {
    super.initState();
    for (final c in widget.project.criteria) {
      final existing = widget.student.scoreFor(c.id);
      _scores[c.id] =
          TextEditingController(text: existing?.value.toString() ?? '');
      _comments[c.id] = TextEditingController(text: existing?.comment ?? '');
      if ((existing?.comment ?? '').isNotEmpty) _commentOpen.add(c.id);
    }
  }

  @override
  void dispose() {
    for (final c in [..._scores.values, ..._comments.values]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Weighted total of the filled-in scores, for the jury member's reference.
  double get _weightedPreview {
    var total = 0.0;
    for (final c in widget.project.criteria) {
      final value = int.tryParse(_scores[c.id]!.text.trim());
      if (value != null) total += value * c.weight;
    }
    return total;
  }

  List<ScoreInput> _collect() {
    final inputs = <ScoreInput>[];
    for (final c in widget.project.criteria) {
      final value = int.tryParse(_scores[c.id]!.text.trim());
      if (value == null) continue;
      inputs.add(ScoreInput(
          criterionId: c.id, value: value, comment: _comments[c.id]!.text));
    }
    return inputs;
  }

  Future<void> _save({required bool submit}) async {
    setState(() {
      _submitAttempted = submit;
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;
    final scores = _collect();
    if (scores.isEmpty) {
      setState(() => _error = 'Enter at least one score.');
      return;
    }
    if (submit) {
      final ok = await _confirmSubmit();
      if (!ok || !mounted) return;
    }

    setState(() => _saving = true);
    final jury = AppServices.of(context).jury;
    try {
      final updated = await jury.saveEvaluation(
        projectId: widget.project.id,
        studentId: widget.student.studentId,
        scores: scores,
        submit: submit,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(submit ? 'Scores submitted and locked.' : 'Draft saved.')),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmSubmit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit scores?'),
        content: Text(
          'Scores for ${widget.student.name} will be locked and cannot be changed afterwards.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Submit')),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              widget.student.name,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text),
            ),
            const SizedBox(height: 2),
            Text(
              _locked
                  ? 'Submitted — scores are locked'
                  : 'Scores from 0 to 100 (whole numbers)',
              style: TextStyle(
                  fontSize: 12,
                  color: _locked ? AppColors.success : Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            for (final c in widget.project.criteria) _buildCriterion(c),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Weighted total',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Text(
                    _weightedPreview.toStringAsFixed(2),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
            if (!_locked) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _confirmed,
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _confirmed = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primary,
                title: const Text('I confirm these scores are final',
                    style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => _save(submit: false),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48)),
                      child: const Text('Save draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving || !_confirmed
                          ? null
                          : () => _save(submit: true),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCriterion(Criterion c) {
    final commentOpen = _commentOpen.contains(c.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text.rich(
                    TextSpan(
                      text: c.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.text),
                      children: [
                        TextSpan(
                          text: '  ${c.weightLabel}',
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade600,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 96,
                child: TextFormField(
                  controller: _scores[c.id],
                  readOnly: _locked,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '—',
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  ),
                  validator: (v) =>
                      validateScore(v, required: _submitAttempted),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (commentOpen)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextFormField(
                controller: _comments[c.id],
                readOnly: _locked,
                enabled: !_saving,
                maxLines: 2,
                maxLength: 1000,
                decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Comment (optional)',
                    counterText: ''),
              ),
            )
          else if (!_locked)
            TextButton.icon(
              onPressed: () => setState(() => _commentOpen.add(c.id)),
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact),
              icon: const Icon(Icons.add_comment_outlined, size: 16),
              label: const Text('Add comment', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
