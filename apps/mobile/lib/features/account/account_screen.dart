import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/ambient_background.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        automaticallyImplyLeading: false,
      ),
      body: AmbientBackground(
        intensity: 0.7,
        child: ListView(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppColors.glowGreen(intensity: 0.65),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.onPrimary,
                    child: Text(
                      (user?.fullName.isNotEmpty ?? false)
                          ? user!.fullName.characters.first
                          : '؟',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'مستخدم',
                          style: const TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.phone ?? user?.email ?? '',
                          style: TextStyle(
                            color: AppColors.onPrimary.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _tile(
              Icons.person_outline,
              'تعديل الملف الشخصي',
              () => context.push('/profile/edit'),
            ),
            _tile(
              Icons.location_on_outlined,
              'عناويني',
              () => context.push('/addresses'),
            ),
            _tile(
              Icons.favorite_border,
              'المفضّلة',
              () => context.push('/favorites'),
            ),
            _tile(
              Icons.notifications_outlined,
              'الإشعارات',
              () => context.push('/notifications'),
            ),
            _tile(
              Icons.receipt_long_outlined,
              'طلباتي',
              () => context.push('/orders'),
            ),
            const Divider(height: 32),
            _tile(
              Icons.logout,
              'تسجيل الخروج',
              () => _logout(context, ref),
              color: AppColors.danger,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    final accent = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: PressableScale(
        onTap: onTap,
        scale: 0.985,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.28)),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color ?? AppColors.dark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (color == null)
                const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.muted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'خروج',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}
