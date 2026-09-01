import '../../core/utils/json.dart';

/// What the backend hands the in-app payment SDK so it can charge the card
/// without leaving the app. The amount is in halalas, the unit Moyasar expects.
class PaymentSession {
  const PaymentSession({
    required this.publishableKey,
    required this.amount,
    required this.currency,
    required this.description,
    required this.orderNumber,
  });

  final String publishableKey;
  final int amount;
  final String currency;
  final String description;
  final String orderNumber;

  factory PaymentSession.fromJson(Map<String, dynamic> json) => PaymentSession(
    publishableKey: json['publishableKey'] as String,
    amount: asInt(json['amount']),
    currency: (json['currency'] as String?) ?? 'SAR',
    description: (json['description'] as String?) ?? '',
    orderNumber: (json['orderNumber'] as String?) ?? '',
  );
}
