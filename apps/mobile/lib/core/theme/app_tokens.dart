import 'package:flutter/material.dart';

/// ALDIAFAH design system — single source of truth for the visual language.
///
/// Values are extracted verbatim from the reference design boards. Do NOT
/// invent, tweak or "improve" these numbers; they mirror the mockups exactly.
/// Every screen must consume these tokens instead of hard-coded values.
abstract class AppTokens {
  AppTokens._();

  // ── Colors ────────────────────────────────────────────────────────────────
  // Reference palette (dark + brand system).
  static const Color background = Color(0xFF050505); // app / splash bg
  static const Color panel = Color(0xFF111111); // dark panels
  static const Color borderDark = Color(0xFF2B2B2B); // dark borders

  static const Color primaryGreen = Color(0xFF1F6E3D);
  static const Color secondaryGreen = Color(0xFF2E8B57);

  static const Color primaryGold = Color(0xFFCFA347);
  static const Color highlightGold = Color(0xFFFFD979);
  static const Color darkGold = Color(0xFF8E6528);

  static const Color white = Color(0xFFFFFFFF);
  static const Color gray = Color(0xFFA6A6A6);

  // Light-surface tokens for the customer mobile app (reference board #3 is a
  // light layout with cream tiles over white).
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceCream = Color(0xFFFFF8E7);
  static const Color surfaceMuted = Color(0xFFF7F9F6);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);

  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color success = Color(0xFF16A34A);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [primaryGreen, Color(0xFF0B3D1E)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkGold, primaryGold, highlightGold],
  );

  // ── Spacing scale (4pt base) ─────────────────────────────────────────────
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;

  // ── Border radius scale ───────────────────────────────────────────────────
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 20;
  static const double radiusPill = 999;

  // ── Shadows (very soft, layered — per spec "no heavy shadow") ─────────────
  static List<BoxShadow> shadowSoft = const [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static List<BoxShadow> shadowCard = const [
    BoxShadow(color: Color(0x1A000000), blurRadius: 22, offset: Offset(0, 10)),
  ];

  // ── Glow (gold bloom used on splash/cards/hover) ──────────────────────────
  static List<BoxShadow> glowGold({double intensity = 1}) => [
        BoxShadow(
          color: primaryGold.withValues(alpha: 0.35 * intensity),
          blurRadius: 16 * intensity,
          spreadRadius: 2 * intensity,
        ),
      ];

  static List<BoxShadow> glowGreen({double intensity = 1}) => [
        BoxShadow(
          color: primaryGreen.withValues(alpha: 0.28 * intensity),
          blurRadius: 22 * intensity,
          offset: const Offset(0, 10),
        ),
      ];

  // ── Motion durations / curves ─────────────────────────────────────────────
  static const Duration splash = Duration(milliseconds: 7000);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOut;
}
