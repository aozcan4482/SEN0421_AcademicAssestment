/// The signed-in user, as returned by the API.
class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.email,
  });

  final int id;
  final String username;
  final String name;
  final String role;
  final String? email;

  bool get isJury => role == 'Jury';

  /// Initials shown in the avatar, e.g. "Demo Jury One" -> "DJ".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['user_id'] as int,
      username: json['username'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      email: json['email'] as String?,
    );
  }
}
