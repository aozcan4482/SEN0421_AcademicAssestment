import '../models/user.dart';
import 'api_client.dart';
import 'session_store.dart';

/// Sign-in, sign-out and session restore.
class AuthService {
  AuthService(this._api, this._store);

  final ApiClient _api;
  final SessionStore _store;

  AppUser? currentUser;

  /// Signs in with CATS (jury/student) or local (admin) credentials.
  /// The password is sent once over the request and never stored.
  Future<AppUser> login(String username, String password) async {
    final json = await _api.post('/auth/login', {
      'username': username,
      'password': password,
    }) as Map<String, dynamic>;
    final token = json['token'] as String;
    final user = AppUser.fromJson(json['user'] as Map<String, dynamic>);
    _api.token = token;
    await _store.saveToken(token);
    currentUser = user;
    return user;
  }

  /// Restores a saved session at app start. Returns null when there is no
  /// saved token or it is no longer valid.
  Future<AppUser?> restoreSession() async {
    final token = await _store.readToken();
    if (token == null) return null;
    _api.token = token;
    try {
      final json = await _api.get('/auth/me') as Map<String, dynamic>;
      currentUser = AppUser.fromJson(json);
      return currentUser;
    } on ApiException catch (e) {
      if (e.isUnauthorized) await logout();
      rethrow;
    }
  }

  Future<void> logout() async {
    _api.token = null;
    currentUser = null;
    await _store.clearToken();
  }
}
