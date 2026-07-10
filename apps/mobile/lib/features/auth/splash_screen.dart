import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/assets/app_assets.dart';
import '../../router/app_router.dart';
import '../../widgets/app_asset.dart';

// ─── Brand Colours ────────────────────────────────────────────────────────────
const _kBlack = Color(0xFF050505);
const _kGold = Color(0xFFCFA347);
const _kGoldLight = Color(0xFFFFD77A);
const _kGreen = Color(0xFF1F6E3D);
const _kGreenLight = Color(0xFF43C46A);

// ─── Splash Screen ───────────────────────────────────────────────────────────
//
// Static resting composition (matches reference "1. شاشة البداية"):
//   • dark bg + gold bokeh particles + soft green vignette
//   • large gold swoosh arc glowing above the brand mark
//   • floating grocery product shots scattered in an arc around the logo
//   • brand mark (gold swoosh + wordmark + 3 descending dots)
//   • main tagline «كل احتياجاتك في مكان واحد» + sub «جودة عالية · أسعار مناسبة · توصيل سريع»
//   • green shopping basket brimming with products (hero, lower-centre)
//   • loading label «جاري تحميل التطبيق...» + green progress bar + percent
//   • bottom line «تجربة تسوق أفضل بانتظارك»
//
// Product shots and the basket load from the asset pipeline by their final
// filenames; until the real art is dropped in they render nothing (no emoji /
// no substitute icon) at the exact reserved size.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  late final Animation<double> _bgFade;
  late final Animation<double> _swoosh;
  late final Animation<double> _logoDraw;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _floatsIn;
  late final Animation<double> _taglineSlide;
  late final Animation<double> _basketRise;
  late final Animation<double> _progressBar;
  late final Animation<double> _loadingFade;

  final List<_Particle> _particles = _generateParticles(64);
  static const List<_FloatSlot> _floatSlots = _kFloatSlots;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          ref.read(splashDoneProvider.notifier).state = true;
        }
      })
      ..forward();

    Animation<double> a(double s, double e, Curve curve) =>
        CurvedAnimation(parent: _ctrl, curve: Interval(s, e, curve: curve));

    _bgFade = a(0.00, 0.14, Curves.easeOut);
    _swoosh = a(0.06, 0.32, Curves.easeOutCubic);
    _logoDraw = a(0.10, 0.36, Curves.easeInOut);
    _logoFade = a(0.10, 0.28, Curves.easeIn);
    _logoScale = a(0.10, 0.34, Curves.easeOutBack);
    _floatsIn = a(0.20, 0.55, Curves.easeOut);
    _taglineSlide = a(0.34, 0.56, Curves.easeOutCubic);
    _basketRise = a(0.36, 0.62, Curves.easeOutCubic);
    _progressBar = a(0.50, 0.98, Curves.easeInOut);
    _loadingFade = a(0.48, 0.60, Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBlack,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => Stack(
              children: [
                // ── Background: warm-dark radial + green bottom vignette ──────
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.35),
                        radius: 1.15,
                        colors: [
                          const Color(0xFF141007)
                              .withValues(alpha: _bgFade.value),
                          _kBlack,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          _kGreen.withValues(alpha: 0.16 * _bgFade.value),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Gold bokeh particle field ─────────────────────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _ctrl.value,
                      density: _bgFade.value,
                    ),
                  ),
                ),

                // ── Large gold swoosh arc above the logo ──────────────────────
                Positioned(
                  left: w * 0.5 - (w * 0.78) / 2,
                  top: h * 0.235,
                  child: Opacity(
                    opacity: _swoosh.value.clamp(0.0, 1.0),
                    child: CustomPaint(
                      size: Size(w * 0.78, w * 0.40),
                      painter: _SwooshArcPainter(progress: _swoosh.value),
                    ),
                  ),
                ),

                // ── Floating product shots (asset-pipeline placeholders) ──────
                ..._buildFloats(w, h),

                // ── Brand mark ────────────────────────────────────────────────
                Positioned(
                  top: h * 0.28,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Transform.scale(
                      scale: 0.6 + _logoScale.value * 0.4,
                      child: Opacity(
                        opacity: _logoFade.value.clamp(0.0, 1.0),
                        child: _AnimatedBrandLogo(
                          drawProgress: _logoDraw.value,
                          size: w * 0.52,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Taglines ──────────────────────────────────────────────────
                Positioned(
                  top: h * 0.57,
                  left: 24,
                  right: 24,
                  child: Opacity(
                    opacity: _taglineSlide.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - _taglineSlide.value)),
                      child: Column(
                        children: [
                          Text(
                            'كل احتياجاتك في مكان واحد',
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 20,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'جودة عالية · أسعار مناسبة · توصيل سريع',
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.cairo(
                              color: _kGold,
                              fontSize: 12.5,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Hero shopping basket ──────────────────────────────────────
                Positioned(
                  top: h * 0.65,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity: _basketRise.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - _basketRise.value)),
                        child: AppAssetImage(
                          AppAssets.splashBasket,
                          width: w * 0.62,
                          height: w * 0.50,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Loading block ─────────────────────────────────────────────
                Positioned(
                  left: 30,
                  right: 30,
                  bottom: 46,
                  child: Opacity(
                    opacity: _loadingFade.value.clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'جاري تحميل التطبيق...',
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 9,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor:
                                      _progressBar.value.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      gradient: const LinearGradient(
                                        colors: [_kGreen, _kGreenLight],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _kGreenLight
                                              .withValues(alpha: 0.55),
                                          blurRadius: 10,
                                          spreadRadius: 0.5,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(_progressBar.value * 100).round()}%',
                              style: GoogleFonts.cairo(
                                color: _kGreenLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'تجربة تسوق أفضل بانتظارك',
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.cairo(
                            color: _kGold.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Floating product shots ───────────────────────────────────────────────
  List<Widget> _buildFloats(double w, double h) {
    return _floatSlots.map((slot) {
      // Staggered appearance across the _floatsIn window.
      final appear =
          ((_floatsIn.value - slot.delay) / 0.30).clamp(0.0, 1.0);
      // Gentle continuous bob once settled.
      final bob = math.sin(_ctrl.value * math.pi * 2 + slot.phase) * 5.0;
      final size = slot.size;
      return Positioned(
        left: w * slot.dx - size / 2,
        top: h * slot.dy - size / 2 + bob,
        child: Opacity(
          opacity: appear,
          child: Transform.scale(
            scale: 0.7 + 0.3 * appear,
            child: AppAssetImage(
              AppAssets.splashFloat(slot.key),
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }).toList();
  }
}

// ─── Floating slot data ───────────────────────────────────────────────────────
class _FloatSlot {
  const _FloatSlot(this.key, this.dx, this.dy, this.size, this.delay,
      this.phase);

  final String key; // → assets/products/splash-<key>.png
  final double dx; // centre-x as fraction of width
  final double dy; // centre-y as fraction of height
  final double size; // logical px
  final double delay; // stagger 0..0.3
  final double phase; // bob phase
}

const List<_FloatSlot> _kFloatSlots = [
  _FloatSlot('chips-a', 0.20, 0.155, 70, 0.00, 0.4),
  _FloatSlot('can-red', 0.44, 0.125, 58, 0.04, 1.1),
  _FloatSlot('can-blue', 0.57, 0.150, 54, 0.08, 2.0),
  _FloatSlot('can-red-2', 0.74, 0.150, 62, 0.06, 0.8),
  _FloatSlot('jar-a', 0.85, 0.215, 56, 0.10, 2.6),
  _FloatSlot('water', 0.13, 0.315, 56, 0.12, 3.2),
  _FloatSlot('chips-b', 0.22, 0.445, 60, 0.16, 1.6),
  _FloatSlot('jar-olive', 0.83, 0.345, 58, 0.14, 0.2),
  _FloatSlot('can-tomato', 0.87, 0.455, 54, 0.18, 2.3),
  _FloatSlot('jar-b', 0.16, 0.560, 56, 0.20, 1.0),
];

// ─── Large gold swoosh arc (glowing crescent above the logo) ──────────────────
class _SwooshArcPainter extends CustomPainter {
  _SwooshArcPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.02, h * 0.92)
      ..quadraticBezierTo(w * 0.50, h * -0.10, w * 0.98, h * 0.92);

    final metrics = path.computeMetrics().first;
    final drawn = metrics.extractPath(0, metrics.length * progress);

    // Outer soft glow.
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = h * 0.10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22)
        ..color = _kGold.withValues(alpha: 0.35 * progress),
    );
    // Bright core.
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = h * 0.03
        ..shader = const LinearGradient(
          colors: [_kGold, _kGoldLight, _kGold],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Travelling sparkle at the tip while drawing.
    if (progress > 0 && progress < 1) {
      final t = metrics.getTangentForOffset(metrics.length * progress);
      if (t != null) {
        canvas.drawCircle(
          t.position,
          h * 0.05,
          Paint()
            ..color = _kGoldLight
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SwooshArcPainter old) =>
      old.progress != progress;
}

// ─── Animated Brand Logo ──────────────────────────────────────────────────────
class _AnimatedBrandLogo extends StatelessWidget {
  const _AnimatedBrandLogo({required this.drawProgress, required this.size});

  final double drawProgress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final h = size * 0.66;
    return SizedBox(
      width: size,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DrawingBrandPainter(progress: drawProgress),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: h * 0.20),
              Opacity(
                opacity: ((drawProgress - 0.5) * 2).clamp(0.0, 1.0),
                child: SizedBox(
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
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [_kGoldLight, _kGold],
                          ).createShader(
                            Rect.fromLTWH(0, 0, size, size * 0.28),
                          ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: h * 0.05),
              Opacity(
                opacity: ((drawProgress - 0.7) * 3.3).clamp(0.0, 1.0),
                child: Text(
                  'ALDIAFAH',
                  style: TextStyle(
                    fontSize: size * 0.085,
                    fontWeight: FontWeight.w700,
                    color: _kGold,
                    letterSpacing: size * 0.03,
                    shadows: [
                      Shadow(
                        color: _kGold.withValues(alpha: 0.8),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawingBrandPainter extends CustomPainter {
  _DrawingBrandPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Inner gold swoosh belonging to the wordmark.
    final innerProgress = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
    if (innerProgress > 0) {
      final innerPath = Path()
        ..moveTo(w * 0.20, h * 0.34)
        ..quadraticBezierTo(w * 0.52, h * 0.02, w * 0.80, h * 0.30);
      final m = innerPath.computeMetrics().first;
      final drawn = m.extractPath(0, m.length * innerProgress);
      canvas.drawPath(
        drawn,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = h * 0.07
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..color = _kGold.withValues(alpha: 0.6 * innerProgress),
      );
      canvas.drawPath(
        drawn,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = h * 0.045
          ..color = _kGold,
      );
    }

    // Three descending gold dots (left of the wordmark).
    final dotOpacity = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
    if (dotOpacity > 0) {
      final dotPaint = Paint()
        ..color = _kGold.withValues(alpha: dotOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * dotOpacity);
      final r = h * 0.045;
      canvas.drawCircle(Offset(w * 0.14, h * 0.58), r * dotOpacity, dotPaint);
      canvas.drawCircle(
          Offset(w * 0.10, h * 0.70), r * 0.85 * dotOpacity, dotPaint);
      canvas.drawCircle(
          Offset(w * 0.07, h * 0.82), r * 0.70 * dotOpacity, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingBrandPainter old) =>
      old.progress != progress;
}

// ─── Particle System ──────────────────────────────────────────────────────────
class _Particle {
  const _Particle({
    required this.x,
    required this.baseY,
    required this.radius,
    required this.speed,
    required this.twinklePhase,
    required this.layer,
  });

  final double x;
  final double baseY;
  final double radius;
  final double speed;
  final double twinklePhase;
  final int layer; // 0=far,1=mid,2=near
}

List<_Particle> _generateParticles(int count) {
  final rnd = math.Random(42);
  return List.generate(count, (_) {
    final layer = rnd.nextInt(3);
    return _Particle(
      x: rnd.nextDouble(),
      baseY: rnd.nextDouble(),
      radius: [0.6, 1.2, 2.0][layer] + rnd.nextDouble() * [0.4, 0.8, 1.0][layer],
      speed: [0.08, 0.15, 0.25][layer] + rnd.nextDouble() * 0.12,
      twinklePhase: rnd.nextDouble() * math.pi * 2,
      layer: layer,
    );
  });
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.density,
  });

  final List<_Particle> particles;
  final double progress;
  final double density;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      var y = (p.baseY - progress * p.speed) % 1.0;
      if (y < 0) y += 1.0;

      final dx = p.x * size.width;
      final dy = y * size.height;

      final twinkle = 0.3 +
          0.7 * (0.5 + 0.5 * math.sin(progress * math.pi * 4 + p.twinklePhase));
      final baseAlpha = [0.3, 0.5, 0.7][p.layer];
      final alpha = baseAlpha * twinkle * density;

      if (p.layer == 2) {
        canvas.drawCircle(
          Offset(dx, dy),
          p.radius * 2.5,
          Paint()
            ..color = _kGold.withValues(alpha: alpha * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      canvas.drawCircle(
        Offset(dx, dy),
        p.radius,
        Paint()..color = _kGold.withValues(alpha: alpha.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress || old.density != density;
}
