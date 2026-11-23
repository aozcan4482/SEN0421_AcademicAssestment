import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the session between app starts.
///
/// The session token is kept in the platform's secure storage (Android
/// Keystore / iOS Keychain), never in plain preferences. Passwords are never
/// stored at all. The server address is not secret and lives in preferences.
class SessionStore {
  SessionStore(this._prefs, {FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ?? const FlutterSecureStorage();

  static const _tokenKey = 'session_token';
  static const _serverKey = 'server_url';

  /// Android emulator address of the host machine; physical devices need the
  /// computer's LAN address, set on the Server Settings screen.
  static const defaultServerUrl = 'http://10.0.2.2:3000';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  static Future<SessionStore> open() async =>
      SessionStore(await SharedPreferences.getInstance());

  String get serverUrl => _prefs.getString(_serverKey) ?? defaultServerUrl;

  Future<void> saveServerUrl(String url) => _prefs.setString(_serverKey, url);

  Future<String?> readToken() => _secure.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _secure.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _secure.delete(key: _tokenKey);
}
