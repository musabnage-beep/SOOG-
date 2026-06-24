import 'package:flutter/material.dart';

/// ALDIAFAH brand palette.
abstract class AppColors {
  static const Color primary = Color(0xFF166534); // deep green
  static const Color secondary = Color(0xFF22C55E); // bright green
  static const Color cream = Color(0xFFFFF8E7);
  static const Color dark = Color(0xFF111827);
  static const Color gold = Color(0xFFD4AF37);

  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7F9F6);
  static const Color muted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color success = Color(0xFF16A34A);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
}
