/// App-wide configuration. Override [apiBaseUrl] at build time with:
/// `flutter run --dart-define=API_BASE_URL=https://api.aldiafah.example/api`
abstract class Env {
  /// Base URL of the ALDIAFAH backend, including the `/api` prefix.
  ///
  /// Defaults to the Android emulator loopback (`10.0.2.2`) so the app talks to
  /// a backend running on the host machine during development.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  /// Optional Google Maps API key for the Android manifest is configured
  /// natively; this value is used only where the SDK needs it at runtime.
  static const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String currency = 'SAR';
}
