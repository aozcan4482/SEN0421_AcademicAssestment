import 'package:flutter/widgets.dart';

import 'api_client.dart';
import 'auth_service.dart';
import 'jury_service.dart';
import 'session_store.dart';

/// Holds the app-wide services and makes them available to every screen
/// through `AppServices.of(context)`.
class AppServices extends InheritedWidget {
  const AppServices({
    super.key,
    required this.api,
    required this.store,
    required this.auth,
    required this.jury,
    required super.child,
  });

  final ApiClient api;
  final SessionStore store;
  final AuthService auth;
  final JuryService jury;

  static AppServices of(BuildContext context) {
    final services = context.dependOnInheritedWidgetOfExactType<AppServices>();
    assert(services != null, 'AppServices not found in the widget tree');
    return services!;
  }

  @override
  bool updateShouldNotify(AppServices oldWidget) => false;
}
