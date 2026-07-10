import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/cart_controller.dart';
import '../../widgets/app_asset.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});

  /// Provided by StatefulShellRoute — gives us currentIndex and goBranch().
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartControllerProvider).count;

    return PopScope(
      // On back press at index 0, exit; otherwise jump back to home tab.
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(0, initialLocation: true);
      },
      child: Scaffold(
        body: shell,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: shell.currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.muted,
          onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          items: [
            const BottomNavigationBarItem(
              icon: _NavIcon(AppAssets.iconHome, fallback: Icons.home_outlined, active: false),
              activeIcon: _NavIcon(AppAssets.iconHome, fallback: Icons.home, active: true),
              label: 'الرئيسية',
            ),
            const BottomNavigationBarItem(
              icon: _NavIcon(AppAssets.iconOffers, fallback: Icons.local_offer_outlined, active: false),
              activeIcon: _NavIcon(AppAssets.iconOffers, fallback: Icons.local_offer, active: true),
              label: 'العروض',
            ),
            BottomNavigationBarItem(
              icon: _CartIcon(count: cartCount, active: false),
              activeIcon: _CartIcon(count: cartCount, active: true),
              label: 'السلة',
            ),
            const BottomNavigationBarItem(
              icon: _NavIcon(AppAssets.iconCategories, fallback: Icons.category_outlined, active: false),
              activeIcon: _NavIcon(AppAssets.iconCategories, fallback: Icons.category, active: true),
              label: 'الأقسام',
            ),
            const BottomNavigationBarItem(
              icon: _NavIcon(AppAssets.iconProfile, fallback: Icons.person_outline, active: false),
              activeIcon: _NavIcon(AppAssets.iconProfile, fallback: Icons.person, active: true),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}

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
    if (count == 0) {
      return AppSvgIcon(
        AppAssets.iconCart,
        size: 24,
        color: color,
        fallback: Icon(Icons.shopping_bag_outlined, color: color),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppSvgIcon(
          AppAssets.iconCart,
          size: 24,
          color: color,
          fallback: Icon(Icons.shopping_bag_outlined, color: color),
        ),
        Positioned(
          top: -4,
          right: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
