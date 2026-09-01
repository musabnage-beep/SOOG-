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

  /// Apple Pay merchant id. It has to match the identifier registered in the
  /// Apple Developer portal, the Xcode entitlement and the Moyasar dashboard.
  /// If any of those is missing the Apple Pay button hides itself and the card
  /// form keeps working, so shipping this before the setup is done is safe.
  static const String applePayMerchantId = String.fromEnvironment(
    'APPLE_PAY_MERCHANT_ID',
    defaultValue: 'merchant.org.aldiafah',
  );
}
