import 'dart:convert';

import 'package:academic_assessment/services/api_client.dart';
import 'package:academic_assessment/services/jury_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _client(MockClientHandler handler) =>
    ApiClient(baseUrl: 'http://server:3000', httpClient: MockClient(handler));

void main() {
  group('ApiClient', () {
    test('prefixes /api and returns decoded JSON', () async {
      late Uri requested;
      final api = _client((req) async {
        requested = req.url;
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });
      final body = await api.get('/health');
      expect(requested.toString(), 'http://server:3000/api/health');
      expect(body, {'status': 'ok'});
    });

    test('sends the bearer token when signed in', () async {
      String? auth;
      final api = _client((req) async {
        auth = req.headers['Authorization'];
        return http.Response('[]', 200);
      })
        ..token = 'abc';
      await api.get('/jury/projects');
      expect(auth, 'Bearer abc');
    });

    test('uses the server error message', () async {
      final api = _client((_) async =>
          http.Response(jsonEncode({'error': 'Access denied'}), 403));
      expect(
        () => api.get('/admin/audit-log'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having((e) => e.message, 'message', 'Access denied')),
      );
    });

    test('calls onUnauthorized on 401 when a token was sent', () async {
      var called = 0;
      final api = _client((_) async =>
          http.Response(jsonEncode({'error': 'Session expired'}), 401))
        ..token = 'expired'
        ..onUnauthorized = () => called++;
      await expectLater(api.get('/auth/me'), throwsA(isA<ApiException>()));
      expect(called, 1);
    });

    test('does not call onUnauthorized for a failed login (no token)',
        () async {
      var called = 0;
      final api = _client(
          (_) async => http.Response(jsonEncode({'error': 'Invalid'}), 401))
        ..onUnauthorized = () => called++;
      await expectLater(
          api.post('/auth/login', {}), throwsA(isA<ApiException>()));
      expect(called, 0);
    });

    test('maps a connection failure to a network error', () async {
      final api = _client((_) async => throw http.ClientException('refused'));
      expect(
        () => api.get('/health'),
        throwsA(isA<ApiException>()
            .having((e) => e.isNetworkError, 'isNetworkError', isTrue)),
      );
    });
  });

  group('JuryService.saveEvaluation', () {
    test('sends scores and the submit flag to the student endpoint', () async {
      late http.Request sent;
      final api = _client((req) async {
        sent = req;
        return http.Response(
          jsonEncode({
            'project_id': 1,
            'project_name': 'P',
            'status': 'In Progress',
            'criteria': <dynamic>[],
            'students': <dynamic>[],
          }),
          200,
        );
      });
      await JuryService(api).saveEvaluation(
        projectId: 1,
        studentId: 4,
        scores: const [
          ScoreInput(criterionId: 1, value: 80, comment: '  Good  '),
          ScoreInput(criterionId: 2, value: 90, comment: ''),
        ],
        submit: true,
      );
      expect(sent.method, 'PUT');
      expect(sent.url.path, '/api/jury/projects/1/students/4/evaluation');
      expect(jsonDecode(sent.body), {
        'scores': [
          {'criteria_id': 1, 'score': 80, 'comment': 'Good'},
          {'criteria_id': 2, 'score': 90},
        ],
        'submit': true,
      });
    });
  });
}
