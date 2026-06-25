import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Animation tracks layered across the timeline (0..1).
  late final Animation<double> _particles; // 0.00 → 1.00  drifting gold motes
  late final Animation<double> _logoScale; // 0.30 → 0.70  logo settles in
  late final Animation<double> _logoFade; // 0.28 → 0.62
  late final Animation<double> _glow; // 0.40 → 0.85   gold halo pulse
  late final Animation<double> _taglineFade; // 0.62 → 0.92
  late final Animation<double> _taglineSlide; // 0.62 → 0.92

  final List<_Particle> _seeds = _buildParticles(36);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();

    _particles = CurvedAnimation(parent: _controller, curve: Curves.linear);
    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.70, curve: Curves.easeOutBack),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 0.62, curve: Curves.easeIn),
    );
    _glow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.85, curve: Curves.easeInOut),
    );
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 0.92, curve: Curves.easeIn),
    );
    _taglineSlide = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 0.92, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B3D1E), // very deep green
                  AppColors.dark, // near-black
                  Color(0xFF0B3D1E),
                ],
                stops: [0, 0.55, 1],
              ),
            ),
            child: Stack(
              children: [
                // Gold particle field.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ParticlePainter(
                      particles: _seeds,
                      progress: _particles.value,
                    ),
                  ),
                ),
                // Center brand + tagline.
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: 0.7 + (_logoScale.value * 0.3),
                        child: Opacity(
                          opacity: _logoFade.value.clamp(0, 1),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(
                                    alpha: 0.45 * _glow.value,
                                  ),
                                  blurRadius: 60 * _glow.value,
                                  spreadRadius: 8 * _glow.value,
                                ),
                              ],
                            ),
                            child: const BrandLogo(size: 220, onDark: true),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Opacity(
                        opacity: _taglineFade.value.clamp(0, 1),
                        child: Transform.translate(
                          offset: Offset(0, 18 * (1 - _taglineSlide.value)),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 3,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              Text(
                                'تسوّق بثقة، نوصلك بسرعة',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Loader pinned to the bottom.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 56,
                  child: Opacity(
                    opacity: _taglineFade.value.clamp(0, 1),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(AppColors.gold),
                        ),
                      ),
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
}

class _Particle {
  const _Particle({
    required this.x,
    required this.baseY,
    required this.radius,
    required this.speed,
    required this.twinklePhase,
  });

  final double x; // 0..1 horizontal position
  final double baseY; // 0..1 starting vertical position
  final double radius; // px
  final double speed; // fraction of height travelled over the timeline
  final double twinklePhase; // radians offset for opacity flicker
}

List<_Particle> _buildParticles(int count) {
  final rnd = math.Random(7);
  return List<_Particle>.generate(count, (_) {
    return _Particle(
      x: rnd.nextDouble(),
      baseY: rnd.nextDouble(),
      radius: 0.8 + rnd.nextDouble() * 2.4,
      speed: 0.15 + rnd.nextDouble() * 0.5,
      twinklePhase: rnd.nextDouble() * math.pi * 2,
    );
  });
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.gold;
    for (final p in particles) {
      // Drift upward, wrapping around the top.
      var y = (p.baseY - progress * p.speed) % 1.0;
      if (y < 0) y += 1.0;
      final dx = p.x * size.width;
      final dy = y * size.height;
      final twinkle =
          0.35 + 0.65 * (0.5 + 0.5 * math.sin(progress * 6.28 * 2 + p.twinklePhase));
      paint.color = AppColors.gold.withValues(alpha: 0.55 * twinkle);
      canvas.drawCircle(Offset(dx, dy), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
