import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/snack.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/ambient_background.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        intensity: 0.45,
        showGold: false,
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const _Header(),
              _ProfileCard(
                name: user?.fullName ?? 'مستخدم',
                contact: user?.phone ?? user?.email ?? '',
                onEdit: () => context.push('/profile/edit'),
              ),
              const SizedBox(height: 24),
              _Section(
                title: 'التسوّق',
                rows: [
                  _Entry(
                    Icons.receipt_long_outlined,
                    'طلباتي',
                    () => context.push('/orders'),
                  ),
                  _Entry(
                    Icons.favorite_border_rounded,
                    'المفضّلة',
                    () => context.push('/favorites'),
                  ),
                  _Entry(
                    Icons.location_on_outlined,
                    'عناويني',
                    () => context.push('/addresses'),
                  ),
                  _Entry(
                    Icons.notifications_none_rounded,
                    'الإشعارات',
                    () => context.push('/notifications'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'الحساب',
                rows: [
                  _Entry(
                    Icons.logout_rounded,
                    'تسجيل الخروج',
                    () => _logout(context, ref),
                    chevron: false,
                  ),
                  _Entry(
                    Icons.delete_forever_outlined,
                    'حذف الحساب',
                    () => _deleteAccount(context, ref),
                    accent: AppColors.danger,
                    chevron: false,
                  ),
                ],
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

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (password == null) return;

    try {
      await ref.read(authControllerProvider.notifier).deleteAccount(password);
      if (context.mounted) showSuccessSnack(context, 'تم حذف حسابك');
    } on ApiException catch (e) {
      if (context.mounted) showErrorSnack(context, e.message);
    }
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(20, 14, 20, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حسابي',
          style: TextStyle(
            color: AppColors.dark,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'الضيافة',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    ),
  );
}

// ── Identity ──────────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.contact,
    required this.onEdit,
  });

  final String name;
  final String contact;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Text(
                name.isEmpty ? '؟' : name.characters.first,
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (contact.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      contact,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Editing lives here instead of in the list below, so the identity
            // block owns everything about "who I am".
            PressableScale(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'تعديل',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grouped list ──────────────────────────────────────────────────────────────
class _Entry {
  const _Entry(
    this.icon,
    this.label,
    this.onTap, {
    this.accent,
    this.chevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;
  final bool chevron;
}

/// A titled group of rows sharing one card, instead of a floating card per row —
/// that repetition is what made the screen read as a pile of buttons.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<_Entry> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsetsDirectional.only(start: 64),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.border,
                      ),
                    ),
                  _SectionRow(entry: rows[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.entry});

  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    final accent = entry.accent ?? AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: entry.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(entry.icon, color: accent, size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  entry.label,
                  style: TextStyle(
                    color: entry.accent ?? AppColors.dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (entry.chevron)
                const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.muted,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks the customer to re-enter their password before closing the account.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _canSubmit = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('حذف الحساب'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'سيتم حذف حسابك وبياناتك الشخصية وعناوينك وسلّتك ومفضّلتك نهائياً، '
            'ولن تتمكّن من تسجيل الدخول بعدها. تُحفظ فواتير طلباتك السابقة '
            'للأغراض النظامية فقط.\n\nأدخل كلمة المرور للتأكيد.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            onChanged: (v) => setState(() => _canSubmit = v.isNotEmpty),
            decoration: const InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed:
              _canSubmit ? () => Navigator.pop(context, _password.text) : null,
          child: const Text(
            'حذف نهائي',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    );
  }
}
