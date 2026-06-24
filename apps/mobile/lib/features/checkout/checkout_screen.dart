import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/address.dart';
import '../../data/models/order.dart';
import '../../providers/address_controller.dart';
import '../../providers/cart_controller.dart';
import '../../providers/core_providers.dart';
import '../../providers/orders_providers.dart';
import '../../providers/settings_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _note = TextEditingController();
  FulfillmentType _type = FulfillmentType.delivery;
  String? _addressId;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(addressControllerProvider.notifier).load();
      final def = ref.read(addressControllerProvider).defaultAddress;
      if (mounted) setState(() => _addressId = def?.id);
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Address? get _selectedAddress {
    final list = ref.read(addressControllerProvider).items;
    for (final a in list) {
      if (a.id == _addressId) return a;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final addresses = ref.watch(addressControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('إتمام الطلب')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('طريقة الاستلام'),
          const SizedBox(height: 10),
          Row(
            children: [
              _typeCard(FulfillmentType.delivery, Icons.delivery_dining, 'توصيل'),
              const SizedBox(width: 12),
              _typeCard(FulfillmentType.pickup, Icons.storefront, 'استلام من المتجر'),
            ],
          ),
          const SizedBox(height: 22),
          if (_type == FulfillmentType.delivery) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionTitle('عنوان التوصيل'),
                TextButton.icon(
                  onPressed: () async {
                    await context.push('/addresses');
                    await ref.read(addressControllerProvider.notifier).load();
                    final def = ref.read(addressControllerProvider).defaultAddress;
                    if (mounted) setState(() => _addressId ??= def?.id);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (addresses.isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (addresses.items.isEmpty)
              _emptyAddresses()
            else
              ...addresses.items.map(_addressTile),
            const SizedBox(height: 22),
            _DeliveryQuoteCard(address: _selectedAddress),
            const SizedBox(height: 22),
          ],
          const _SectionTitle('ملاحظات (اختياري)'),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'أي تعليمات خاصة بالطلب...',
            ),
          ),
          const SizedBox(height: 22),
          _OrderSummary(subtotal: cart.subtotal, address: _selectedAddress, type: _type),
        ],
      ),
      bottomNavigationBar: _bottom(cart.subtotal),
    );
  }

  Widget _typeCard(FulfillmentType type, IconData icon, String label) {
    final active = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? AppColors.primary : AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: active ? Colors.white : AppColors.primary, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.dark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addressTile(Address a) {
    final selected = a.id == _addressId;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: a.id,
        groupValue: _addressId,
        onChanged: (v) => setState(() => _addressId = v),
        activeColor: AppColors.primary,
        title: Text(a.label ?? a.city,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(a.summary),
      ),
    );
  }

  Widget _emptyAddresses() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_outlined, color: AppColors.muted),
          const SizedBox(width: 10),
          const Expanded(child: Text('لا توجد عناوين محفوظة')),
          TextButton(
            onPressed: () async {
              await context.push('/addresses');
              await ref.read(addressControllerProvider.notifier).load();
            },
            child: const Text('أضف عنواناً'),
          ),
        ],
      ),
    );
  }

  Widget _bottom(double subtotal) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _placing ? null : _placeOrder,
          child: _placing
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('تأكيد الطلب'),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_type == FulfillmentType.delivery && _addressId == null) {
      _show('اختر عنوان التوصيل');
      return;
    }
    setState(() => _placing = true);
    try {
      final order = await ref.read(orderRepositoryProvider).checkout(
            fulfillmentType: _type,
            addressId: _type == FulfillmentType.delivery ? _addressId : null,
            customerNote: _note.text.trim(),
          );
      await ref.read(cartControllerProvider.notifier).load();
      ref.invalidate(myOrdersProvider);
      if (!mounted) return;
      context.pushReplacement('/order/${order.id}');
    } on ApiException catch (e) {
      _show(e.message);
    } catch (_) {
      _show('تعذّر إتمام الطلب.');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800));
}

class _DeliveryQuoteCard extends ConsumerWidget {
  const _DeliveryQuoteCard({required this.address});

  final Address? address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (address == null) return const SizedBox.shrink();
    final quote = ref.watch(deliveryQuoteProvider(
      DeliveryQuoteArgs(latitude: address!.latitude, longitude: address!.longitude),
    ));
    return quote.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Text(e.toString(), style: const TextStyle(color: AppColors.danger)),
      data: (q) {
        if (!q.withinRange) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                SizedBox(width: 10),
                Expanded(child: Text('هذا الموقع خارج نطاق التوصيل')),
              ],
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _row('المسافة', Formatters.distance(q.distanceMeters)),
              const SizedBox(height: 6),
              _row('الوقت المتوقّع', Formatters.eta(q.etaMinutes)),
              const SizedBox(height: 6),
              _row('رسوم التوصيل',
                  q.freeDelivery ? 'مجاني' : Formatters.money(q.fee)),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
}

class _OrderSummary extends ConsumerWidget {
  const _OrderSummary({required this.subtotal, required this.address, required this.type});

  final double subtotal;
  final Address? address;
  final FulfillmentType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double fee = 0;
    if (type == FulfillmentType.delivery && address != null) {
      final quote = ref.watch(deliveryQuoteProvider(
        DeliveryQuoteArgs(latitude: address!.latitude, longitude: address!.longitude),
      ));
      fee = quote.maybeWhen(
        data: (q) => q.freeDelivery ? 0 : q.fee,
        orElse: () => 0,
      );
    }
    final total = subtotal + fee;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _row('الإجمالي الفرعي', Formatters.money(subtotal)),
          const SizedBox(height: 8),
          _row('رسوم التوصيل',
              type == FulfillmentType.pickup ? '—' : Formatters.money(fee)),
          const Divider(height: 24),
          _row('الإجمالي', Formatters.money(total), bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: bold ? AppColors.dark : AppColors.muted,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                fontSize: bold ? 17 : 14,
              )),
          Text(value,
              style: TextStyle(
                color: bold ? AppColors.primary : AppColors.dark,
                fontWeight: FontWeight.w800,
                fontSize: bold ? 17 : 14,
              )),
        ],
      );
}
