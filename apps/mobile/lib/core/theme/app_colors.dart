import 'package:flutter/material.dart';

/// ALDIAFAH brand palette — light theme.
///
/// Names are stable: every screen already consumes these tokens, so the whole
/// app re-skins from here. `dark` means "primary ink" and `cream` means "raised
/// surface" — both are semantic, not literal, so call sites keep reading
/// correctly whichever way the theme points.
///
/// Every ink/surface pair below clears WCAG AA (4.5:1). The greens are deep
/// rather than bright because a light accent on a white surface cannot carry
/// text — prices and links are drawn in [primary], so it has to be readable,
/// not just decorative.
abstract class AppColors {
  // ── Brand greens ──────────────────────────────────────────────────────────
  /// Accent used for CTAs, prices, active states. 5.5:1 on white.
  static const Color primary = Color(0xFF137A3F);

  /// Lighter green for gradients and secondary emphasis.
  static const Color secondary = Color(0xFF1FA34F);

  /// Banner / hero base green. Dark on purpose: hero cards stay dark green
  /// with white text, the way the storefront draws them.
  static const Color deepGreen = Color(0xFF0E2A1B);

  // ── Light surfaces ────────────────────────────────────────────────────────
  /// Slightly off-white so white cards lift off the page.
  static const Color background = Color(0xFFF6F8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEEF2EC);
  static const Color border = Color(0xFFDFE6DE);

  // ── Text & icons ──────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);

  /// Primary ink. (Legacy name — reads as "the strong color".)
  static const Color dark = Color(0xFF14211A);
  static const Color muted = Color(0xFF6B7A70);

  /// Ink used on top of [primary] fills.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Raised surface.
  static const Color cream = surfaceAlt;

  // ── Accents ───────────────────────────────────────────────────────────────
  /// Decorative only — too light to carry body text on white.
  static const Color gold = Color(0xFFCFA347);
  static const Color danger = Color(0xFFD92D20);
  static const Color warning = Color(0xFFB54708);
  static const Color success = primary;

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  /// Hero / promotional banner fill. Stays dark so white text sits on it.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF17512E), Color(0xFF0B2415)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E6528), gold, Color(0xFFF2DCA6)],
  );

  // ── Glows ─────────────────────────────────────────────────────────────────
  /// Reads as a green-tinted shadow on a light page. Kept faint: a strong glow
  /// over white looks like a smudge rather than depth.
  static List<BoxShadow> glowGreen({double intensity = 1}) => [
    BoxShadow(
      color: primary.withValues(alpha: 0.18 * intensity),
      blurRadius: 22 * intensity,
      offset: Offset(0, 6 * intensity),
    ),
  ];

  static List<BoxShadow> glowGold({double intensity = 1}) => [
    BoxShadow(
      color: gold.withValues(alpha: 0.28 * intensity),
      blurRadius: 20 * intensity,
      offset: Offset(0, 6 * intensity),
    ),
  ];

  /// Soft lift used on cards over the off-white background.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0F16281D), blurRadius: 16, offset: Offset(0, 6)),
  ];
}
