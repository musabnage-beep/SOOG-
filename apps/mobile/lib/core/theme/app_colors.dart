import 'package:flutter/material.dart';

/// ALDIAFAH brand palette. Values mirror [AppTokens] (the design system).
abstract class AppColors {
  static const Color primary = Color(0xFF1F6E3D); // primary green (reference)
  static const Color secondary = Color(0xFF2E8B57); // secondary green
  static const Color cream = Color(0xFFFFF8E7);
  static const Color dark = Color(0xFF111111);
  static const Color gold = Color(0xFFCFA347); // primary gold (reference)

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
