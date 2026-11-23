import 'package:material_ui/material_ui.dart';

import '../config/app_theme.dart';
import '../services/api_client.dart';
import '../services/app_services.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// First screen: restores a saved session, then opens Home or Login.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  static const route = '/';

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _restore();
    }
  }

  Future<void> _restore() async {
    final auth = AppServices.of(context).auth;
    String? message;
    var signedIn = false;
    try {
      final user = await auth.restoreSession();
      signedIn = user != null && user.isJury;
    } on ApiException catch (e) {
      // Offline or server down: let the user check the server address.
      if (!e.isUnauthorized) message = e.message;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      signedIn ? HomeScreen.route : LoginScreen.route,
      arguments: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}
