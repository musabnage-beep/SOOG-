import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/order_repository.dart';

/// Asks the backend for a gateway session and opens the hosted payment page in
/// the system browser. Returns false (after showing why) when it cannot start.
///
/// The browser is deliberately external: the gateway page is where mada, Apple
/// Pay and 3-D Secure run, and Safari is the only place Apple Pay is offered.
Future<bool> openPaymentPage(
  ScaffoldMessengerState messenger,
  OrderRepository orders,
  String orderId,
) async {
  void fail(String message) {
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  try {
    final url = await orders.initiatePayment(orderId);
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) fail('تعذّر فتح صفحة الدفع.');
    return opened;
  } on ApiException catch (e) {
    fail(e.message);
    return false;
  } catch (_) {
    fail('تعذّر بدء عملية الدفع.');
    return false;
  }
}
