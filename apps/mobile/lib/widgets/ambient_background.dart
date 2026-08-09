import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Slow, GPU-cheap ambient glow painted behind premium screens.
///
/// It is a single [CustomPaint] driven by one [AnimationController] that paints
/// two or three soft radial blobs — no blur filters, no particle lists, no
/// per-frame allocations. Honours `MediaQuery.disableAnimations` (the platform
/// "reduce motion" accessibility setting) by rendering a static frame.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({
    super.key,
    this.child,
    this.intensity = 1,
    this.showGold = true,
  });

  final Widget? child;

  /// 0 → invisible, 1 → default strength. Keep low on dense/readable screens.
  final double intensity;

  /// Adds a third, gold-tinted blob. Used on hero surfaces (splash, welcome).
  final bool showGold;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      if (_running) {
        _c.stop();
        _running = false;
      }
      _c.value = 0.25;
    } else if (!_running) {
      _c.repeat();
      _running = true;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _AmbientPainter(
                progress: _c,
                intensity: widget.intensity,
                showGold: widget.showGold,
              ),
            ),
          ),
        ),
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({
    required this.progress,
    required this.intensity,
    required this.showGold,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final double intensity;
  final bool showGold;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    final t = progress.value * 2 * math.pi;

    _blob(
      canvas,
      size,
      center: Offset(
        size.width * (0.22 + 0.10 * math.sin(t)),
        size.height * (0.18 + 0.06 * math.cos(t * 0.8)),
      ),
      radius: size.shortestSide * 0.85,
      color: AppColors.primary.withValues(alpha: 0.13 * intensity),
    );

    _blob(
      canvas,
      size,
      center: Offset(
        size.width * (0.86 + 0.08 * math.cos(t * 0.7)),
        size.height * (0.72 + 0.08 * math.sin(t * 0.9)),
      ),
      radius: size.shortestSide * 0.95,
      color: AppColors.secondary.withValues(alpha: 0.11 * intensity),
    );

    if (showGold) {
      _blob(
        canvas,
        size,
        center: Offset(
          size.width * (0.55 + 0.14 * math.sin(t * 0.55 + 1.4)),
          size.height * (0.45 + 0.10 * math.cos(t * 0.6)),
        ),
        radius: size.shortestSide * 0.62,
        color: AppColors.gold.withValues(alpha: 0.06 * intensity),
      );
    }
  }

  void _blob(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
        stops: const [0, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_AmbientPainter old) =>
      old.intensity != intensity || old.showGold != showGold;
}

/// A rounded, slightly translucent panel — the app's standard card surface.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
    this.borderColor,
    this.color,
    this.glow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: glow
            ? AppColors.glowGreen(intensity: 0.5)
            : AppColors.cardShadow,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

/// Fades + slides its child in once, staggered by [index].
///
/// Used for list/grid entrance choreography. Cheap: one short controller per
/// item, disposed with the element.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 18,
  });

  final Widget child;
  final int index;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 40 * (widget.index % 8));
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _a.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Scales down slightly while pressed — the app's standard tap feedback.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _down = false),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
