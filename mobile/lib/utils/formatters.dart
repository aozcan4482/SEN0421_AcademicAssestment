/// Small, dependency-free formatting and validation helpers.
library;

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "15 Dec 2026  •  10:00"
String formatDateTime(DateTime? dt) {
  if (dt == null) return 'Date not set';
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '${dt.day} ${_months[dt.month - 1]} ${dt.year}  •  $hour:$minute';
}

/// Validates a score field. Returns an error message, or null when valid.
/// Empty is allowed for drafts; [required] makes it mandatory (submit).
String? validateScore(String? input, {bool required = false}) {
  final text = (input ?? '').trim();
  if (text.isEmpty) return required ? 'Required' : null;
  final value = int.tryParse(text);
  if (value == null) return 'Whole number';
  if (value < 0 || value > 100) return '0 – 100';
  return null;
}

/// Normalises a server URL entered by the user: trims, adds http:// when no
/// scheme is given and removes trailing slashes.
String normaliseServerUrl(String input) {
  var url = input.trim();
  if (url.isEmpty) return url;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'http://$url';
  }
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  return url;
}
