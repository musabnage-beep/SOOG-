import 'package:flutter/material.dart';
import 'package:moyasar/moyasar.dart';

import '../../core/config/env.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/payment_session.dart';
import '../../data/repositories/order_repository.dart';

/// Opens the in-app payment screen and resolves to true once the order is paid.
///
/// The card is charged by the Moyasar SDK inside the app — no browser, no
/// hosted page — and the resulting charge is verified server-side before the
/// order is settled.
Future<bool> openPaymentPage(
  BuildContext context,
  OrderRepository orders,
  String orderId,
) async {
  final paid = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => PaymentScreen(orders: orders, orderId: orderId),
    ),
  );
  return paid ?? false;
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.orders, required this.orderId});

  final OrderRepository orders;
  final String orderId;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Future<PaymentSession> _session;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _session = widget.orders.paymentSession(widget.orderId);
  }

  PaymentConfig _config(PaymentSession session) => PaymentConfig(
    publishableApiKey: session.publishableKey,
    amount: session.amount,
    currency: session.currency,
    description: session.description,
    // The gateway echoes this back on the webhook, which is how a payment that
    // the app never got to report still reconciles to its order.
    metadata: {'order_id': widget.orderId, 'order_number': session.orderNumber},
    supportedNetworks: [
      PaymentNetwork.mada,
      PaymentNetwork.visa,
      PaymentNetwork.masterCard,
    ],
    creditCard: CreditCardConfig(saveCard: false, manual: false),
    applePay: ApplePayConfig(
      merchantId: Env.applePayMerchantId,
      label: 'الضيافة',
      manual: false,
      saveCard: false,
    ),
  );

  void _onPaymentResult(dynamic result) {
    if (result is PaymentResponse) {
      if (result.status == PaymentStatus.paid) {
        _confirm(result.id);
      } else {
        _fail(_sourceMessage(result) ?? 'لم تكتمل عملية الدفع.');
      }
      return;
    }
    // The SDK reports cancellation as an error; the customer chose to go back,
    // so it is not worth a red banner.
    if (result is PaymentCanceledError) return;
    _fail(_errorMessage(result));
  }

  /// Hands the charge to the backend, which verifies it against the gateway.
  Future<void> _confirm(String paymentId) async {
    setState(() => _confirming = true);
    try {
      final status = await widget.orders.confirmPayment(
        widget.orderId,
        paymentId,
      );
      if (!mounted) return;
      if (status == 'PAID') {
        Navigator.of(context).pop(true);
      } else {
        _fail('لم تكتمل عملية الدفع.');
      }
    } on ApiException catch (e) {
      _fail(e.message);
    } catch (_) {
      // The money may well have been taken; the webhook settles the order, so
      // tell the customer to check rather than to pay again.
      _fail('تم الدفع لكن تعذّر تأكيده. راجع حالة الطلب بعد قليل.');
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('الدفع')),
    body: FutureBuilder<PaymentSession>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return _Message(
            error is ApiException ? error.message : 'تعذّر بدء عملية الدفع.',
          );
        }

        final config = _config(snapshot.data!);
        return AbsorbPointer(
          absorbing: _confirming,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (_confirming)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(),
                ),
              ApplePay(
                config: config,
                onPaymentResult: _onPaymentResult,
                buttonType: ApplePayButtonType.buy,
              ),
              const SizedBox(height: 8),
              CreditCard(
                config: config,
                onPaymentResult: _onPaymentResult,
                locale: const Localization.ar(),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.muted),
      ),
    ),
  );
}

String? _sourceMessage(PaymentResponse result) {
  final source = result.source;
  if (source is CardPaymentResponseSource) return source.message;
  if (source is ApplePayPaymentResponseSource) return source.message;
  return null;
}

String _errorMessage(dynamic result) {
  if (result is ApiError) return result.message;
  if (result is AuthError) return result.message;
  if (result is ValidationError) return result.message;
  if (result is NetworkError) return 'تعذّر الاتصال. تحقق من الإنترنت.';
  if (result is TimeoutError) return 'انتهت مهلة العملية. حاول مجدداً.';
  return 'تعذّر إتمام الدفع.';
}
