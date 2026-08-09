import 'package:flutter/material.dart';

/// ALDIAFAH brand palette — premium dark theme.
///
/// Names are stable: every screen already consumes these tokens, so the whole
/// app re-skins from here. `dark` and `cream` are kept as semantic aliases
/// (`dark` = primary text/icon ink, `cream` = raised surface) so existing call
/// sites keep reading correctly on a dark background.
abstract class AppColors {
  // ── Brand greens ──────────────────────────────────────────────────────────
  /// Bright accent used for CTAs, prices, active states.
  static const Color primary = Color(0xFF7ED957);

  /// Deeper green for gradients and secondary emphasis.
  static const Color secondary = Color(0xFF1DB954);

  /// Banner / hero base green.
  static const Color deepGreen = Color(0xFF0F3D22);

  // ── Dark surfaces ─────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0D0F0E);
  static const Color surface = Color(0xFF1B1F1D);
  static const Color surfaceAlt = Color(0xFF242A24);
  static const Color border = Color(0xFF2C332E);

  // ── Text & icons ──────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);

  /// Primary ink on dark surfaces. (Legacy name — reads as "the strong color".)
  static const Color dark = Color(0xFFF2F5F3);
  static const Color muted = Color(0xFFB0B8B3);

  /// Ink used on top of [primary] fills.
  static const Color onPrimary = Color(0xFF08150D);

  /// Raised surface. (Legacy name from the light theme.)
  static const Color cream = surfaceAlt;

  // ── Accents ───────────────────────────────────────────────────────────────
  static const Color gold = Color(0xFFF5C44B);
  static const Color danger = Color(0xFFFF5A52);
  static const Color warning = Color(0xFFF5A524);
  static const Color success = Color(0xFF7ED957);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  /// Hero / promotional banner fill.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF1A5A32), Color(0xFF0B2415)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E6528), gold, Color(0xFFFFE9A8)],
  );

  // ── Glows ─────────────────────────────────────────────────────────────────
  static List<BoxShadow> glowGreen({double intensity = 1}) => [
    BoxShadow(
      color: primary.withValues(alpha: 0.28 * intensity),
      blurRadius: 24 * intensity,
      spreadRadius: 1 * intensity,
    ),
  ];

  static List<BoxShadow> glowGold({double intensity = 1}) => [
    BoxShadow(
      color: gold.withValues(alpha: 0.30 * intensity),
      blurRadius: 20 * intensity,
      spreadRadius: 1 * intensity,
    ),
  ];

  /// Soft lift used on cards over the near-black background.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)),
  ];
}
