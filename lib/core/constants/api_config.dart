import 'package:flutter/foundation.dart';

/// Where the backend lives.
///
/// Run on a real phone (same Wi-Fi as your PC):
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3000
/// Run fully offline with mock data (old behaviour):
///   flutter run --dart-define=USE_BACKEND=false
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// false = no server: local profile + mock AI, like before the backend.
  static const bool useBackend = bool.fromEnvironment(
    'USE_BACKEND',
    defaultValue: true,
  );

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000'; // Android emulator -> your PC
    }
    return 'http://localhost:3000'; // Windows, web, iOS simulator
  }
}