import 'package:material_ui/material_ui.dart';

import '../config/app_theme.dart';
import '../services/api_client.dart';
import '../services/app_services.dart';
import '../services/session_store.dart';
import '../utils/formatters.dart';

/// Lets the user point the app at the backend (e.g. the computer's LAN
/// address) and test the connection through GET /api/health.
class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  static const route = '/settings';

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _controller = TextEditingController();
  bool _testing = false;
  String? _result;
  bool _ok = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _controller.text = AppServices.of(context).store.serverUrl;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final url = normaliseServerUrl(_controller.text);
    setState(() {
      _testing = true;
      _result = null;
    });
    final probe = ApiClient(baseUrl: url, timeout: const Duration(seconds: 5));
    try {
      final json = await probe.get('/health') as Map<String, dynamic>;
      final dbUp = json['database'] == 'up';
      if (!mounted) return;
      setState(() {
        _ok = dbUp;
        _result = dbUp
            ? 'Connected. Server and database are up.'
            : 'Server reached, but its database is down.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _ok = false;
        _result = e.statusCode == 503
            ? 'Server reached, but its database is down.'
            : e.message;
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final services = AppServices.of(context);
    final url = normaliseServerUrl(_controller.text);
    if (url.isEmpty) return;
    await services.store.saveServerUrl(url);
    services.api.baseUrl = url;
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Server address saved.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Server settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Server address',
              hintText: 'http://192.168.1.20:3000',
              prefixIcon: Icon(Icons.dns_outlined),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Android emulator: ${SessionStore.defaultServerUrl}\n'
            'Phone on the same Wi-Fi: http://<computer IPv4 address>:3000 '
            '(find it with "ipconfig" on the computer).',
            style: TextStyle(fontSize: 12, color: AppColors.text),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.network_check),
                  label: const Text('Test connection'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    ElevatedButton(onPressed: _save, child: const Text('Save')),
              ),
            ],
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _ok ? Icons.check_circle_outline : Icons.error_outline,
                  color: _ok ? AppColors.success : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_result!)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
