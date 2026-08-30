/// App-wide configuration. Override [apiBaseUrl] at build time with:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api`
abstract class Env {
  /// Base URL of the ALDIAFAH backend, including the `/api` prefix.
  ///
  /// Must stay HTTPS: plain HTTP is rejected by Apple's App Transport Security
  /// and is silently rewritten by some ISPs into an HTML captive page, which
  /// makes every JSON decode fail.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.aldiafah.org/api',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String currency = 'SAR';
}
