import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/order_repository.dart';

/// Asks the backend for a gateway session and opens the hosted payment page in
/// an in-app browser sheet. Returns false (after showing why) when it cannot
/// start.
///
/// The page stays inside the app: `inAppBrowserView` maps to
/// SFSafariViewController on iOS and Custom Tabs on Android. That keeps mada,
/// Apple Pay and 3-D Secure working — Apple supports Apple Pay in Safari *and*
/// SFSafariViewController — without kicking the customer out to another app.
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
      mode: LaunchMode.inAppBrowserView,
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
