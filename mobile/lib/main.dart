import 'package:material_ui/material_ui.dart';

import 'config/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/server_settings_screen.dart';
import 'screens/startup_screen.dart';
import 'services/api_client.dart';
import 'services/app_services.dart';
import 'services/auth_service.dart';
import 'services/jury_service.dart';
import 'services/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = await SessionStore.open();
  final api = ApiClient(baseUrl: store.serverUrl);
  final auth = AuthService(api, store);
  final jury = JuryService(api);

  runApp(AcademicAssessmentApp(api: api, store: store, auth: auth, jury: jury));
}

class AcademicAssessmentApp extends StatefulWidget {
  const AcademicAssessmentApp({
    super.key,
    required this.api,
    required this.store,
    required this.auth,
    required this.jury,
  });

  final ApiClient api;
  final SessionStore store;
  final AuthService auth;
  final JuryService jury;

  @override
  State<AcademicAssessmentApp> createState() => _AcademicAssessmentAppState();
}

class _AcademicAssessmentAppState extends State<AcademicAssessmentApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // When the session expires, sign out and go back to the login screen.
    widget.api.onUnauthorized = () async {
      await widget.auth.logout();
      _navigatorKey.currentState
          ?.pushNamedAndRemoveUntil(LoginScreen.route, (_) => false);
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
            content: Text('Your session has expired. Please sign in again.')),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppServices(
      api: widget.api,
      store: widget.store,
      auth: widget.auth,
      jury: widget.jury,
      child: MaterialApp(
        title: 'Academic Assessment',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _messengerKey,
        initialRoute: StartupScreen.route,
        routes: {
          StartupScreen.route: (_) => const StartupScreen(),
          LoginScreen.route: (_) => const LoginScreen(),
          HomeScreen.route: (_) => const HomeScreen(),
          ServerSettingsScreen.route: (_) => const ServerSettingsScreen(),
        },
      ),
    );
  }
}
