import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/assets/app_assets.dart';
import '../core/theme/app_colors.dart';

/// ALDIAFAH brand wordmark — a sweeping arc (swoosh) with a gold accent of
/// three descending dots and the Arabic logotype "الضيافة" + latin "ALDIAFAH".
///
/// Prefers the official vector asset (`assets/logo/logo.svg`, or
/// `logo-white.svg` on dark) when it is present, so dropping the real logo file
/// swaps it everywhere automatically. Until then it falls back to the built-in
/// vector mark below (the current brand mark — never a random placeholder).
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 120,
    this.onDark = false,
    this.showLatin = true,
  });

  /// Logical width of the mark. Height is derived (~0.62 × size).
  final double size;

  /// Use light-on-dark colors for dark backgrounds.
  final bool onDark;

  /// Whether to render the latin "ALDIAFAH" sub-wordmark.
  final bool showLatin;

  static final Map<String, Future<bool>> _presence = {};

  static Future<bool> _exists(BuildContext context, String path) {
    return _presence.putIfAbsent(path, () async {
      try {
        await DefaultAssetBundle.of(context).loadString(path);
        return true;
      } catch (_) {
        return false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = onDark ? AppAssets.logoWhite : AppAssets.logoSvg;
    return FutureBuilder<bool>(
      future: _exists(context, assetPath),
      builder: (context, snap) {
        if (snap.data == true) {
          return SizedBox(
            width: size,
            child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
          );
        }
        return _buildVectorMark(context);
      },
    );
  }

  Widget _buildVectorMark(BuildContext context) {
    final arcColor = onDark ? AppColors.white : AppColors.primary;
    final wordColor = onDark ? AppColors.white : AppColors.dark;
    final height = size * 0.62;

    return SizedBox(
      width: size,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The swoosh arc + descending gold dots.
          Positioned.fill(
            child: CustomPaint(
              painter: _BrandPainter(arcColor: arcColor),
            ),
          ),
          // Wordmark.
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: height * 0.18),
              SizedBox(
                width: size * 0.92,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'الضيافة',
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.cairo(
                      fontSize: size * 0.28,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: wordColor,
                    ),
                  ),
                ),
              ),
              if (showLatin) ...[
                SizedBox(height: height * 0.04),
                Text(
                  'ALDIAFAH',
                  style: TextStyle(
                    fontSize: size * 0.085,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    letterSpacing: size * 0.03,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandPainter extends CustomPainter {
  _BrandPainter({required this.arcColor});

  final Color arcColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sweeping arc above the wordmark — two strokes for a layered swoosh.
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = arcColor;

    final outer = Path()
      ..moveTo(w * 0.08, h * 0.40)
      ..quadraticBezierTo(w * 0.50, h * -0.16, w * 0.92, h * 0.34);
    arc.strokeWidth = h * 0.075;
    canvas.drawPath(outer, arc);

    final inner = Path()
      ..moveTo(w * 0.20, h * 0.34)
      ..quadraticBezierTo(w * 0.52, h * 0.02, w * 0.80, h * 0.30);
    arc.strokeWidth = h * 0.045;
    arc.color = AppColors.gold;
    canvas.drawPath(inner, arc);

    // Three descending gold dots (the accent in the brand mark).
    final dot = Paint()..color = AppColors.gold;
    final r = h * 0.045;
    canvas.drawCircle(Offset(w * 0.14, h * 0.58), r, dot);
    canvas.drawCircle(Offset(w * 0.10, h * 0.70), r * 0.85, dot);
    canvas.drawCircle(Offset(w * 0.07, h * 0.82), r * 0.7, dot);
  }

  @override
  bool shouldRepaint(covariant _BrandPainter oldDelegate) =>
      oldDelegate.arcColor != arcColor;
}
