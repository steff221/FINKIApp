// Backend base URL. Override per environment with:
//   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080/api
//
// Sensible defaults during development:
//   - iOS simulator:    http://localhost:8080/api
//   - Android emulator: http://10.0.2.2:8080/api  (host loopback)
//   - Physical device:  pass --dart-define with your machine's LAN IP
import 'dart:io' show Platform;

class Env {
  static const String _override =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Build-time baked credentials for silent auto-login (no login screen).
  /// Pass with: --dart-define=AUTH_EMAIL=... --dart-define=AUTH_PASSWORD=...
  static const String defaultEmail =
      String.fromEnvironment('AUTH_EMAIL', defaultValue: '');
  static const String defaultPassword =
      String.fromEnvironment('AUTH_PASSWORD', defaultValue: '');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    // Sensible per-platform localhost default for the simulator/emulator.
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080/api';
    } catch (_) {
      // Platform unavailable (e.g. tests) — fall through.
    }
    return 'http://localhost:8080/api';
  }
}
