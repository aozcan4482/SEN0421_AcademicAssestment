import 'package:material_ui/material_ui.dart';

import '../config/app_theme.dart';
import '../services/api_client.dart';
import '../services/app_services.dart';
import 'home_screen.dart';
import 'server_settings_screen.dart';

/// Sign-in with CATS credentials (jury members).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const route = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  bool _argumentRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A message passed by the startup screen (e.g. server unreachable).
    if (!_argumentRead) {
      _argumentRead = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String) _error = arg;
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = AppServices.of(context).auth;
    try {
      final user = await auth.login(_username.text.trim(), _password.text);
      if (!user.isJury) {
        await auth.logout();
        if (mounted) {
          setState(() =>
              _error = 'The mobile app currently supports jury members only.');
        }
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(HomeScreen.route);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      _password.clear();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.fact_check_outlined,
                        size: 72, color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Academic Assessment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign in with your CATS account',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.text),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _username,
                      enabled: !_busy,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your username'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter your password'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBox(message: _error!),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('SIGN IN',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context)
                              .pushNamed(ServerSettingsScreen.route),
                      icon: const Icon(Icons.settings_ethernet, size: 18),
                      label: const Text('Server settings'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(message, style: const TextStyle(color: AppColors.text))),
        ],
      ),
    );
  }
}
