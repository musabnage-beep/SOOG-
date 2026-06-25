import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/address.dart';
import '../../providers/address_controller.dart';
import '../../widgets/state_views.dart';
import '../checkout/map_picker_screen.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(addressControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addressControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('عناويني')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAddress,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('عنوان جديد', style: TextStyle(color: Colors.white)),
      ),
      body: state.isLoading
          ? const AppLoader()
          : state.items.isEmpty
              ? const EmptyView(
                  icon: Icons.location_off_outlined,
                  title: 'لا توجد عناوين',
                  subtitle: 'أضف عنواناً لتسهيل التوصيل',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _AddressTile(
                    address: state.items[i],
                    onDelete: () => _delete(state.items[i]),
                  ),
                ),
    );
  }

  Future<void> _addAddress() async {
    final picked = await context.push<MapPickerResult>('/map-picker');
    if (picked == null || !mounted) return;
    await _openForm(picked);
  }

  Future<void> _openForm(MapPickerResult picked) async {
    final labelCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: picked.city);
    final districtCtrl = TextEditingController(text: picked.district);
    final streetCtrl = TextEditingController(text: picked.street);
    bool isDefault = false;
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('تفاصيل العنوان',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(
                        labelText: 'اسم العنوان (المنزل، العمل...)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(labelText: 'المدينة'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: districtCtrl,
                    decoration: const InputDecoration(labelText: 'الحي'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: streetCtrl,
                    decoration: const InputDecoration(labelText: 'الشارع'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: isDefault,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تعيين كعنوان افتراضي'),
                    onChanged: (v) => setSheet(() => isDefault = v),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (cityCtrl.text.trim().isEmpty ||
                                streetCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text('أدخل المدينة والشارع'),
                                    backgroundColor: AppColors.danger),
                              );
                              return;
                            }
                            setSheet(() => saving = true);
                            try {
                              await ref.read(addressControllerProvider.notifier).create({
                                'label': labelCtrl.text.trim(),
                                'city': cityCtrl.text.trim(),
                                'district': districtCtrl.text.trim(),
                                'street': streetCtrl.text.trim(),
                                'latitude': picked.latitude,
                                'longitude': picked.longitude,
                                'isDefault': isDefault,
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                            } on ApiException catch (e) {
                              setSheet(() => saving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                      content: Text(e.message),
                                      backgroundColor: AppColors.danger),
                                );
                              }
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('حفظ العنوان'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _delete(Address a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العنوان'),
        content: const Text('هل تريد حذف هذا العنوان؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(addressControllerProvider.notifier).remove(a.id);
    }
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.address, required this.onDelete});

  final Address address;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(address.label ?? address.city,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('افتراضي',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(address.summary, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}
