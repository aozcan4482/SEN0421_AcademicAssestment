import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// An error returned by the API or raised while reaching it.
/// [statusCode] is 0 when the server could not be reached at all.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetworkError => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin JSON-over-HTTP client for the REST API.
///
/// * Adds the session token as `Authorization: Bearer <token>`.
/// * Turns every failure into an [ApiException] with a message that can be
///   shown to the user; the server's `{ "error": ... }` text is used when
///   available.
/// * Calls [onUnauthorized] on 401 so the app can return to the login screen
///   when the session expires.
class ApiClient {
  ApiClient(
      {required this.baseUrl,
      http.Client? httpClient,
      this.timeout = const Duration(seconds: 15)})
      : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Duration timeout;

  /// e.g. http://10.0.2.2:3000 (no trailing slash, no /api).
  String baseUrl;

  /// Session token; null when signed out.
  String? token;

  /// Invoked when an authenticated request is rejected with 401.
  void Function()? onUnauthorized;

  Uri _uri(String path) => Uri.parse('$baseUrl/api$path');

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) =>
      _send(() => _http.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, [Object? body]) => _send(() =>
      _http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> put(String path, Object body) => _send(
      () => _http.put(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final hadToken = token != null;
    http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(0, 'The server did not respond in time.');
    } on FormatException {
      throw const ApiException(0, 'The server address is not valid.');
    } catch (_) {
      throw const ApiException(0,
          'Cannot reach the server. Check the server address and your network.');
    }

    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body is Map<String, dynamic> && body['error'] is String
        ? body['error'] as String
        : 'Request failed (${response.statusCode}).';
    if (response.statusCode == 401 && hadToken) {
      onUnauthorized?.call();
    }
    throw ApiException(response.statusCode, message);
  }

  static dynamic _decode(String text) {
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }
}
