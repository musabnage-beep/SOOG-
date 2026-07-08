import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/catalog_providers.dart';
import '../../widgets/product_card.dart';
import '../../widgets/state_views.dart';

const _kBg = Color(0xFF0A1A0C);

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsControllerProvider(const ProductQuery()));

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Title pill ──────────────────────────────────────────
            const SliverToBoxAdapter(child: _TitlePill()),

            // ── Hero banner ─────────────────────────────────────────
            const SliverToBoxAdapter(child: _HeroBanner()),

            // ── Deal cards ──────────────────────────────────────────
            const SliverToBoxAdapter(child: _DealCardsRow()),

            // ── Section heading ─────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text(
                  'جميع المنتجات',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // ── Products grid ────────────────────────────────────────
            if (products.isLoading)
              const SliverFillRemaining(child: Center(child: AppLoader()))
            else if (products.error != null && products.items.isEmpty)
              SliverFillRemaining(
                child: ErrorView(
                  message: products.error!,
                  onRetry: () => ref
                      .read(productsControllerProvider(const ProductQuery()).notifier)
                      .refresh(),
                ),
              )
            else if (products.items.isEmpty)
              const SliverFillRemaining(
                child: EmptyView(
                  icon: Icons.local_offer_outlined,
                  title: 'لا توجد عروض حالياً',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = products.items[i];
                      return ProductCard(
                        product: p,
                        onTap: () => context.push('/product/${p.id}'),
                      );
                    },
                    childCount: products.items.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.66,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Title pill
// ─────────────────────────────────────────────────────────────────────────────

class _TitlePill extends StatelessWidget {
  const _TitlePill();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'العروض',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero banner
// ─────────────────────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0C3A1C), Color(0xFF1F6E3D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Left: icon placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: Color(0xFFCFA347),
                    size: 40,
                  ),
                ),
                const SizedBox(width: 16),
                // Right: text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCFA347),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'حصري',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'عروض حصرية',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'خصومات تصل إلى ٥٠٪',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Color(0xFFA3C9A3),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'تسوق الآن',
                            style: TextStyle(
                              color: Color(0xFF0C3A1C),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Three deal cards row
// ─────────────────────────────────────────────────────────────────────────────

class _DealCardsRow extends StatelessWidget {
  const _DealCardsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: const [
          Expanded(child: _CountdownDealCard()),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                _SimpleDealCard(
                  label: 'عروض الأسبوع',
                  icon: Icons.calendar_view_week_rounded,
                  color: Color(0xFF1A3A5C),
                  accent: Color(0xFF4A9EE0),
                ),
                SizedBox(height: 10),
                _SimpleDealCard(
                  label: 'عروض الشهر',
                  icon: Icons.calendar_month_rounded,
                  color: Color(0xFF3A1A2E),
                  accent: Color(0xFFCFA347),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today's deal card with countdown
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownDealCard extends StatefulWidget {
  const _CountdownDealCard();

  @override
  State<_CountdownDealCard> createState() => _CountdownDealCardState();
}

class _CountdownDealCardState extends State<_CountdownDealCard> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    // Countdown to end of day
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _remaining = endOfDay.difference(now);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds > 0) {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = _pad(_remaining.inHours);
    final m = _pad(_remaining.inMinutes.remainder(60));
    final s = _pad(_remaining.inSeconds.remainder(60));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'عرض اليوم',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFCFA347),
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _TimeBox(value: s, unit: 'ث'),
              const _TimeSep(),
              _TimeBox(value: m, unit: 'د'),
              const _TimeSep(),
              _TimeBox(value: h, unit: 'س'),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'ينتهي العرض قريباً',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Color(0xFFA3C9A3),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'احصل عليه',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.value, required this.unit});
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1A0C),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFFCFA347),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: const TextStyle(color: Color(0xFFA3C9A3), fontSize: 9),
        ),
      ],
    );
  }
}

class _TimeSep extends StatelessWidget {
  const _TimeSep();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10, left: 3, right: 3),
      child: Text(
        ':',
        style: TextStyle(
          color: Color(0xFFCFA347),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple deal card (weekly / monthly)
// ─────────────────────────────────────────────────────────────────────────────

class _SimpleDealCard extends StatelessWidget {
  const _SimpleDealCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: accent, size: 20),
        ],
      ),
    );
  }
}
