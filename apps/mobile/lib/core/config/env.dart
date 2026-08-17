/// App-wide configuration. Override [apiBaseUrl] at build time with:
/// `flutter run --dart-define=API_BASE_URL=https://api.aldiafah.com/api`
abstract class Env {
  /// Base URL of the ALDIAFAH backend, including the `/api` prefix.
  ///
  /// Defaults to the Android emulator loopback (`10.0.2.2`) so the app talks to
  /// a backend running on the host machine during development.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://18.194.190.26:3000/api',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String currency = 'SAR';
}
