import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moyasar/moyasar.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
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

  // Apple Pay is deliberately absent: it needs a merchant id registered with
  // Apple, the in-app-payments entitlement and a certificate uploaded to the
  // gateway. Until all three exist the button renders but cannot open the
  // payment sheet, which reads as a broken screen.
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

        final session = snapshot.data!;
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
              _AmountCard(session: session),
              const SizedBox(height: 20),
              _CardForm(
                config: _config(session),
                amount: session.amount,
                onPaymentResult: _onPaymentResult,
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// What the customer is about to pay, before any card detail is asked for.
class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.session});

  final PaymentSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المبلغ المستحق',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'طلب ${session.orderNumber}',
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            // The gateway counts in halalas; the customer thinks in riyals.
            Formatters.money(session.amount / 100),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// The card form, written against the app's own theme.
///
/// The SDK ships a ready-made form, but it hardcodes a white sheet, black
/// labels and a blue button, which is unreadable on a dark screen. Only the
/// look is ours: the card details still go straight to the gateway through
/// [Moyasar.pay], and the 3-D Secure step below is the same redirect flow.
class _CardForm extends StatefulWidget {
  const _CardForm({
    required this.config,
    required this.amount,
    required this.onPaymentResult,
  });

  final PaymentConfig config;
  final int amount;
  final void Function(dynamic result) onPaymentResult;

  @override
  State<_CardForm> createState() => _CardFormState();
}

class _CardFormState extends State<_CardForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvc.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final expiry = _expiry.text.split('/');
    final card = CardFormModel(
      name: _name.text.trim(),
      number: _digits(_number.text),
      month: expiry.first.trim(),
      year: expiry.last.trim(),
      cvc: _cvc.text.trim(),
    );

    setState(() => _submitting = true);
    dynamic result;
    try {
      result = await Moyasar.pay(
        apiKey: widget.config.publishableApiKey,
        paymentRequest: PaymentRequest(
          widget.config,
          CardPaymentRequestSource(
            creditCardData: card,
            tokenizeCard: false,
            manualPayment: false,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        widget.onPaymentResult(ApiError(e.toString()));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);

    // Anything but `initiated` is a final answer; only `initiated` means the
    // bank wants the customer to authenticate first.
    if (result is! PaymentResponse ||
        result.status != PaymentStatus.initiated) {
      widget.onPaymentResult(result);
      return;
    }
    _run3ds(result);
  }

  Future<void> _run3ds(PaymentResponse response) async {
    final source = response.source as CardPaymentResponseSource;
    final url = source.transactionUrl ?? '';
    if (url.isEmpty) {
      widget.onPaymentResult(UnprocessableTokenError());
      return;
    }

    final outcome = await Navigator.of(context).push<_ThreeDSOutcome>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ThreeDSScreen(transactionUrl: url),
      ),
    );
    if (!mounted) return;

    // A closed sheet with no outcome means the customer backed out.
    if (outcome == null) {
      widget.onPaymentResult(PaymentCanceledError());
      return;
    }
    if (outcome.status == PaymentStatus.paid.name) {
      response.status = PaymentStatus.paid;
    } else if (outcome.status == PaymentStatus.authorized.name) {
      response.status = PaymentStatus.authorized;
    } else {
      response.status = PaymentStatus.failed;
      source.message = outcome.message;
    }
    widget.onPaymentResult(response);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'بيانات البطاقة',
            style: TextStyle(
              color: AppColors.dark,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.characters,
            // The gateway only accepts the Latin name embossed on the card.
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z. ]')),
            ],
            decoration: const InputDecoration(
              labelText: 'الاسم على البطاقة',
              hintText: 'AHMED ALI',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: _validateName,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _number,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'رقم البطاقة',
              hintText: '0000 0000 0000 0000',
              prefixIcon: Icon(Icons.credit_card),
            ),
            validator: _validateNumber,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiry,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'الانتهاء',
                    hintText: 'MM/YY',
                  ),
                  validator: _validateExpiry,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cvc,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'CVC',
                    hintText: '123',
                  ),
                  validator: _validateCvc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitting ? null : _pay,
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.onPrimary,
                    ),
                  )
                : Text('ادفع ${Formatters.money(widget.amount / 100)}'),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 15, color: AppColors.muted),
              SizedBox(width: 6),
              Text(
                'دفع آمن عبر ميسر',
                style: TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _digits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

String? _validateName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'أدخل الاسم كما هو على البطاقة';
  // The gateway rejects a single word, so ask for both names up front.
  if (name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).length < 2) {
    return 'أدخل الاسم الأول واسم العائلة';
  }
  return null;
}

String? _validateNumber(String? value) {
  final number = _digits(value ?? '');
  if (number.isEmpty) return 'أدخل رقم البطاقة';
  if (number.length < 13 || !_passesLuhn(number)) return 'رقم البطاقة غير صحيح';
  return null;
}

String? _validateExpiry(String? value) {
  final parts = (value ?? '').split('/');
  if (parts.length != 2 || parts[1].length != 2) return 'التاريخ غير مكتمل';
  final month = int.tryParse(parts[0]);
  final year = int.tryParse(parts[1]);
  if (month == null || year == null || month < 1 || month > 12) {
    return 'التاريخ غير صحيح';
  }
  // A card is valid through the last day of its month, so compare against the
  // first day of the next one.
  final now = DateTime.now();
  if (DateTime(2000 + year, month + 1).isBefore(now)) {
    return 'البطاقة منتهية';
  }
  return null;
}

String? _validateCvc(String? value) {
  final cvc = value?.trim() ?? '';
  if (cvc.isEmpty) return 'أدخل الرمز';
  if (cvc.length < 3) return 'الرمز غير صحيح';
  return null;
}

bool _passesLuhn(String number) {
  var sum = 0;
  for (var i = 0; i < number.length; i++) {
    var digit = int.parse(number[number.length - 1 - i]);
    if (i.isOdd) digit *= 2;
    sum += digit > 9 ? digit - 9 : digit;
  }
  return sum % 10 == 0;
}

/// Groups the card number in fours while it is typed.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _digits(newValue.text);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Turns four typed digits into MM/YY.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _digits(newValue.text);
    final text = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ThreeDSOutcome {
  const _ThreeDSOutcome(this.status, this.message);

  final String status;
  final String message;
}

/// The bank's 3-D Secure page. It ends by redirecting to the gateway's
/// callback URL carrying the verdict in the query string.
class _ThreeDSScreen extends StatefulWidget {
  const _ThreeDSScreen({required this.transactionUrl});

  final String transactionUrl;

  @override
  State<_ThreeDSScreen> createState() => _ThreeDSScreenState();
}

class _ThreeDSScreenState extends State<_ThreeDSScreen> {
  late final WebViewController _controller;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final callbackHost = Uri.parse(PaymentConfig.callbackUrl).host;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            final uri = Uri.parse(url);
            if (_done || uri.host != callbackHost) return;
            _done = true;
            Navigator.of(context).pop(
              _ThreeDSOutcome(
                uri.queryParameters['status'] ?? '',
                uri.queryParameters['message'] ?? '',
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.transactionUrl));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('التحقق من البطاقة')),
    body: SafeArea(child: WebViewWidget(controller: _controller)),
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
