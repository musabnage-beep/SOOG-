import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../router/app_router.dart';

// ─── Brand Colours ────────────────────────────────────────────────────────────
const _kBlack = Color(0xFF050505);
const _kGold = Color(0xFFCFA347);
const _kGoldLight = Color(0xFFFFD77A);
const _kGoldDark = Color(0xFF8C6528);
const _kGreen = Color(0xFF1F6E3D);

// ─── Splash Screen ───────────────────────────────────────────────────────────
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // ── Scene timings (0..1 over 7 000 ms) ──────────────────────────────────
  // Scene 1  0.000 → 0.143   Black bg + particles
  // Scene 2  0.143 → 0.286   Logo draws (stroke animation)
  // Scene 3  0.286 → 0.571   Products orbit
  // Scene 4  0.571 → 0.714   Products dissolve → glow
  // Scene 5  0.714 → 1.000   Progress bar + loading text

  late final Animation<double> _particles;
  late final Animation<double> _logoDraw;
  late final Animation<double> _logoGlow;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _orbitProgress;
  late final Animation<double> _orbitFade;
  late final Animation<double> _progressBar;
  late final Animation<double> _loadingFade;
  late final Animation<double> _taglineSlide;

  final List<_Particle> _particles60 = _generateParticles(60);
  final List<_OrbitItem> _orbitItems = _buildOrbitItems();

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

    Animation<double> _c(double s, double e, Curve curve) =>
        CurvedAnimation(parent: _ctrl, curve: Interval(s, e, curve: curve));

    _particles = _c(0.0, 1.0, Curves.linear);
    _logoDraw = _c(0.143, 0.300, Curves.easeInOut);
    _logoGlow = _c(0.250, 0.450, Curves.easeOut);
    _logoFade = _c(0.143, 0.286, Curves.easeIn);
    _logoScale = _c(0.143, 0.310, Curves.easeOutBack);
    _orbitProgress = _c(0.286, 0.714, Curves.linear);
    _orbitFade = _c(0.571, 0.714, Curves.easeIn);
    _progressBar = _c(0.714, 0.980, Curves.easeOut);
    _loadingFade = _c(0.700, 0.800, Curves.easeIn);
    _taglineSlide = _c(0.750, 0.920, Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: _kBlack,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => Stack(
          children: [
            // ── Background gradient ─────────────────────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      _kGreen.withValues(
                          alpha: 0.18 * _logoDraw.value.clamp(0, 1)),
                      _kBlack,
                    ],
                  ),
                ),
              ),
            ),

            // ── Particle field ──────────────────────────────────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles60,
                  progress: _particles.value,
                  sceneProgress: _ctrl.value,
                ),
              ),
            ),

            // ── Orbiting product icons ──────────────────────────────────────
            if (_orbitProgress.value > 0)
              ..._buildOrbitWidgets(size),

            // ── Logo glow bloom ─────────────────────────────────────────────
            if (_logoGlow.value > 0)
              Center(
                child: Container(
                  width: size.width * 0.7,
                  height: size.width * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kGold.withValues(
                          alpha: 0.25 * _logoGlow.value *
                              (1 - _orbitFade.value * 0.4),
                        ),
                        blurRadius: 120 * _logoGlow.value,
                        spreadRadius: 10 * _logoGlow.value,
                      ),
                    ],
                  ),
                ),
              ),

            // ── Logo ────────────────────────────────────────────────────────
            Center(
              child: Transform.scale(
                scale: 0.5 + _logoScale.value * 0.5,
                child: Opacity(
                  opacity: _logoFade.value.clamp(0.0, 1.0),
                  child: _AnimatedBrandLogo(
                    drawProgress: _logoDraw.value,
                    size: 260,
                  ),
                ),
              ),
            ),

            // ── Progress bar + loading text ─────────────────────────────────
            if (_loadingFade.value > 0)
              Positioned(
                left: 32,
                right: 32,
                bottom: 60,
                child: Opacity(
                  opacity: _loadingFade.value.clamp(0.0, 1.0),
                  child: Column(
                    children: [
                      // Tagline
                      Transform.translate(
                        offset: Offset(0, 16 * (1 - _taglineSlide.value)),
                        child: Opacity(
                          opacity: _taglineSlide.value.clamp(0.0, 1.0),
                          child: Text(
                            'تجربة تسوق أفضل بانتظارك',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Loading label + percentage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'جاري تحميل التطبيق...',
                            style: GoogleFonts.cairo(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(_progressBar.value * 100).toInt()}%',
                            style: GoogleFonts.cairo(
                              color: _kGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Progress track
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressBar.value.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: const LinearGradient(
                                colors: [_kGreen, _kGold],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _kGold.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Orbit widgets ──────────────────────────────────────────────────────────
  List<Widget> _buildOrbitWidgets(Size screen) {
    final cx = screen.width / 2;
    final cy = screen.height / 2 - 20;
    final orbitFadeOut = _orbitFade.value;
    final opacity = (1.0 - orbitFadeOut).clamp(0.0, 1.0);

    return _orbitItems.map((item) {
      final angle = item.startAngle +
          _orbitProgress.value * math.pi * 2 * item.speed;
      final r = item.radius * math.min(screen.width, screen.height) * 0.38;
      final x = cx + math.cos(angle) * r;
      final y = cy + math.sin(angle) * r * 0.45; // flatten orbit (perspective)
      final scale = 0.7 + 0.3 * (1 + math.sin(angle)) / 2;

      // Appear staggered
      final appearStart = item.appearDelay;
      final appear = ((_orbitProgress.value - appearStart) / 0.15)
          .clamp(0.0, 1.0);

      return Positioned(
        left: x - 28,
        top: y - 28,
        child: Opacity(
          opacity: (appear * opacity).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale * appear,
            child: _ProductOrb(emoji: item.emoji, glow: _kGold),
          ),
        ),
      );
    }).toList();
  }
}

// ─── Animated Brand Logo ──────────────────────────────────────────────────────
class _AnimatedBrandLogo extends StatelessWidget {
  const _AnimatedBrandLogo({required this.drawProgress, required this.size});

  final double drawProgress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final h = size * 0.62;
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
              SizedBox(height: h * 0.18),
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
                            colors: [Colors.white, _kGoldLight],
                          ).createShader(
                            Rect.fromLTWH(0, 0, size, size * 0.28),
                          ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: h * 0.04),
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

    // Outer arc (white stroke) — drawn first half of progress
    final outerPath = Path()
      ..moveTo(w * 0.08, h * 0.40)
      ..quadraticBezierTo(w * 0.50, h * -0.16, w * 0.92, h * 0.34);

    final outerMetrics = outerPath.computeMetrics().first;
    final outerLen = outerMetrics.length * (progress * 2).clamp(0.0, 1.0);
    final outerDrawn = outerMetrics.extractPath(0, outerLen);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * 0.075
      ..color = Colors.white.withValues(alpha: 0.95);

    // Glow pass
    if (progress > 0) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = h * 0.10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..color = _kGold.withValues(alpha: 0.5 * progress.clamp(0.0, 1.0));
      canvas.drawPath(outerDrawn, glowPaint);
    }
    canvas.drawPath(outerDrawn, arcPaint);

    // Trailing sparkle at stroke tip
    if (outerLen > 0 && outerLen < outerMetrics.length) {
      final tangent = outerMetrics.getTangentForOffset(outerLen);
      if (tangent != null) {
        final sparkPaint = Paint()
          ..color = _kGoldLight.withValues(alpha: 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(tangent.position, h * 0.06, sparkPaint);
      }
    }

    // Inner gold arc — drawn in second half
    final innerProgress = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
    if (innerProgress > 0) {
      final innerPath = Path()
        ..moveTo(w * 0.20, h * 0.34)
        ..quadraticBezierTo(w * 0.52, h * 0.02, w * 0.80, h * 0.30);

      final innerMetrics = innerPath.computeMetrics().first;
      final innerLen = innerMetrics.length * innerProgress;
      final innerDrawn = innerMetrics.extractPath(0, innerLen);

      final innerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = h * 0.045
        ..color = _kGold;

      // Glow
      final innerGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = h * 0.07
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = _kGold.withValues(alpha: 0.6 * innerProgress);
      canvas.drawPath(innerDrawn, innerGlow);
      canvas.drawPath(innerDrawn, innerPaint);

      // Sparkle at inner tip
      if (innerLen < innerMetrics.length) {
        final t = innerMetrics.getTangentForOffset(innerLen);
        if (t != null) {
          canvas.drawCircle(
            t.position,
            h * 0.05,
            Paint()
              ..color = _kGoldLight
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
        }
      }
    }

    // Three gold dots
    final dotOpacity = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
    if (dotOpacity > 0) {
      final dotPaint = Paint()
        ..color = _kGold.withValues(alpha: dotOpacity)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          4 * dotOpacity,
        );
      final r = h * 0.045;
      canvas.drawCircle(Offset(w * 0.14, h * 0.58), r * dotOpacity, dotPaint);
      canvas.drawCircle(
          Offset(w * 0.10, h * 0.70), r * 0.85 * dotOpacity, dotPaint);
      canvas.drawCircle(
          Offset(w * 0.07, h * 0.82), r * 0.7 * dotOpacity, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingBrandPainter old) =>
      old.progress != progress;
}

// ─── Product Orb Widget ───────────────────────────────────────────────────────
class _ProductOrb extends StatelessWidget {
  const _ProductOrb({required this.emoji, required this.glow});

  final String emoji;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(
          color: glow.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}

// ─── Orbit Item Data ──────────────────────────────────────────────────────────
class _OrbitItem {
  const _OrbitItem({
    required this.emoji,
    required this.startAngle,
    required this.radius,
    required this.speed,
    required this.appearDelay,
  });

  final String emoji;
  final double startAngle; // radians
  final double radius; // fraction of min(w,h)
  final double speed; // rotations per full orbit progress (0→1)
  final double appearDelay; // when to start appearing (0..0.5)
}

List<_OrbitItem> _buildOrbitItems() {
  const items = [
    ('🧀', 0.0, 0.90, 0.85, 0.00),
    ('🍅', 0.79, 0.75, 1.10, 0.05),
    ('🫒', 1.57, 0.95, 0.75, 0.10),
    ('🥛', 2.36, 0.80, 0.90, 0.15),
    ('🍪', 3.14, 0.85, 1.05, 0.20),
    ('🌽', 3.93, 0.70, 0.80, 0.25),
    ('🥝', 4.71, 0.92, 1.15, 0.30),
    ('🫙', 5.50, 0.78, 0.95, 0.35),
  ];
  return items
      .map((t) => _OrbitItem(
            emoji: t.$1,
            startAngle: t.$2,
            radius: t.$3,
            speed: t.$4,
            appearDelay: t.$5,
          ))
      .toList();
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
    required this.sceneProgress,
  });

  final List<_Particle> particles;
  final double progress;
  final double sceneProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final densityFactor = sceneProgress < 0.143
        ? sceneProgress / 0.143
        : 1.0;

    for (final p in particles) {
      var y = (p.baseY - progress * p.speed) % 1.0;
      if (y < 0) y += 1.0;

      final dx = p.x * size.width;
      final dy = y * size.height;

      final twinkle = 0.3 +
          0.7 * (0.5 + 0.5 * math.sin(progress * math.pi * 4 + p.twinklePhase));

      final baseAlpha = [0.3, 0.5, 0.7][p.layer];
      final alpha = baseAlpha * twinkle * densityFactor;

      // Glow for near-layer particles
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
      old.progress != progress || old.sceneProgress != sceneProgress;
}
