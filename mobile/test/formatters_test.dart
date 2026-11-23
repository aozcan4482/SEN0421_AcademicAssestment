import 'package:academic_assessment/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateScore', () {
    test('accepts whole numbers from 0 to 100', () {
      expect(validateScore('0'), isNull);
      expect(validateScore('100'), isNull);
      expect(validateScore(' 75 '), isNull);
    });

    test('rejects values outside the range', () {
      expect(validateScore('-1'), isNotNull);
      expect(validateScore('101'), isNotNull);
    });

    test('rejects decimals and text', () {
      expect(validateScore('75.5'), isNotNull);
      expect(validateScore('abc'), isNotNull);
    });

    test('empty is allowed for drafts but required for submit', () {
      expect(validateScore(''), isNull);
      expect(validateScore('', required: true), 'Required');
      expect(validateScore(null, required: true), 'Required');
    });
  });

  group('normaliseServerUrl', () {
    test('adds http:// when no scheme is given', () {
      expect(
          normaliseServerUrl('192.168.1.20:3000'), 'http://192.168.1.20:3000');
    });

    test('keeps https and removes trailing slashes', () {
      expect(normaliseServerUrl(' https://api.example.edu// '),
          'https://api.example.edu');
    });

    test('returns empty for empty input', () {
      expect(normaliseServerUrl('   '), '');
    });
  });

  group('formatDateTime', () {
    test('formats day, month, year and time', () {
      expect(formatDateTime(DateTime(2026, 12, 15, 9, 5)),
          '15 Dec 2026  •  09:05');
    });

    test('handles a missing date', () {
      expect(formatDateTime(null), 'Date not set');
    });
  });
}
