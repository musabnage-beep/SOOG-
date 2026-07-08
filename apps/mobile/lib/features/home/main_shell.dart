import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/cart_controller.dart';
import '../../widgets/app_asset.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _tabs = ['/home', '/offers', '/cart', '/categories', '/account'];

  int _indexFor(String location) {
    final i = _tabs.indexWhere((t) => location.startsWith(t));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);
    final cartCount = ref.watch(cartControllerProvider).count;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        onTap: (i) => context.go(_tabs[i]),
        items: [
          // الرئيسية
          const BottomNavigationBarItem(
            icon: _NavIcon(AppAssets.iconHome, fallback: Icons.home_outlined, active: false),
            activeIcon: _NavIcon(AppAssets.iconHome, fallback: Icons.home, active: true),
            label: 'الرئيسية',
          ),
          // العروض
          const BottomNavigationBarItem(
            icon: _NavIcon(AppAssets.iconOffers, fallback: Icons.local_offer_outlined, active: false),
            activeIcon: _NavIcon(AppAssets.iconOffers, fallback: Icons.local_offer, active: true),
            label: 'العروض',
          ),
          // السلة
          BottomNavigationBarItem(
            icon: _CartIcon(count: cartCount, active: false),
            activeIcon: _CartIcon(count: cartCount, active: true),
            label: 'السلة',
          ),
          // الأقسام
          const BottomNavigationBarItem(
            icon: _NavIcon(AppAssets.iconCategories, fallback: Icons.category_outlined, active: false),
            activeIcon: _NavIcon(AppAssets.iconCategories, fallback: Icons.category, active: true),
            label: 'الأقسام',
          ),
          // حسابي
          const BottomNavigationBarItem(
            icon: _NavIcon(AppAssets.iconProfile, fallback: Icons.person_outline, active: false),
            activeIcon: _NavIcon(AppAssets.iconProfile, fallback: Icons.person, active: true),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}

/// Bottom-nav icon backed by the branded golden SVG set. Until the real
/// `assets/icons/<name>.svg` is dropped in, it degrades to the matching Material
/// [fallback] so the nav is never blank and keeps its active/inactive colour.
class _NavIcon extends StatelessWidget {
  const _NavIcon(this.asset, {required this.fallback, required this.active});

  final String asset;
  final IconData fallback;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.muted;
    return AppSvgIcon(
      asset,
      size: 24,
      color: color,
      fallback: Icon(fallback, color: color),
    );
  }
}

class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.count, required this.active});

  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.muted;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppSvgIcon(
          AppAssets.iconCart,
          size: 24,
          color: color,
          fallback: Icon(
            active ? Icons.shopping_cart : Icons.shopping_cart_outlined,
            color: color,
          ),
        ),
        if (count > 0)
          Positioned(
            top: -6,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
