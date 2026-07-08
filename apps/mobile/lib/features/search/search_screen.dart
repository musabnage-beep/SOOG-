import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/catalog_providers.dart';
import '../../widgets/product_card.dart';
import '../../widgets/state_views.dart';

const _kBg = Color(0xFF0A1A0C);
const _kCard = Color(0xFF0F2414);
const _kHistoryKey = 'search_history';
const _kMaxHistory = 8;

// ─────────────────────────────────────────────────────────────────────────────
// Search history provider (local prefs)
// ─────────────────────────────────────────────────────────────────────────────

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>(
  (ref) => SearchHistoryNotifier(),
);

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_kHistoryKey) ?? [];
  }

  Future<void> add(String query) async {
    if (query.trim().isEmpty) return;
    final list = [query, ...state.where((q) => q != query)];
    state = list.take(_kMaxHistory).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kHistoryKey, state);
  }

  Future<void> remove(String query) async {
    state = state.where((q) => q != query).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kHistoryKey, state);
  }

  Future<void> clear() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryKey);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search screen
// ─────────────────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    final trimmed = query.trim();
    setState(() => _query = trimmed);
    if (trimmed.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).add(trimmed);
    }
  }

  void _clear() {
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // ── Pill title ───────────────────────────────────────────
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'البحث',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Search field ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  onSubmitted: _search,
                  onChanged: (v) {
                    if (v.trim().isEmpty) setState(() => _query = '');
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF5A7A5A),
                      fontSize: 14,
                    ),
                    hintTextDirection: TextDirection.rtl,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    prefixIcon: _query.isNotEmpty
                        ? IconButton(
                            onPressed: _clear,
                            icon: const Icon(Icons.close,
                                color: Color(0xFF5A7A5A), size: 18),
                          )
                        : null,
                    suffixIcon: IconButton(
                      onPressed: () => _search(_controller.text),
                      icon: const Icon(Icons.search,
                          color: AppColors.primary, size: 22),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Body ─────────────────────────────────────────────────
            Expanded(
              child: _query.isEmpty
                  ? _HistoryView(onSelect: (q) {
                      _controller.text = q;
                      _search(q);
                    })
                  : _ResultsView(query: _query),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History chips
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryView extends ConsumerWidget {
  const _HistoryView({required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(searchHistoryProvider);

    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_outlined, color: Color(0xFF2A4A2A), size: 56),
            SizedBox(height: 12),
            Text(
              'ابحث عن ما تريد',
              style: TextStyle(color: Color(0xFF5A7A5A), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () =>
                    ref.read(searchHistoryProvider.notifier).clear(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('مسح الكل', style: TextStyle(fontSize: 13)),
              ),
              const Text(
                'عمليات البحث الأخيرة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: history
                .map(
                  (q) => _HistoryChip(
                    label: q,
                    onTap: () => onSelect(q),
                    onDelete: () =>
                        ref.read(searchHistoryProvider.notifier).remove(q),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({
    required this.label,
    required this.onTap,
    required this.onDelete,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close,
                  size: 14, color: Color(0xFF5A7A5A)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFA3C9A3),
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.history, size: 13, color: Color(0xFF5A7A5A)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search results grid
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsView extends ConsumerWidget {
  const _ResultsView({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(
      productsControllerProvider(ProductQuery(search: query)),
    );

    if (products.isLoading) {
      return const Center(child: AppLoader());
    }

    if (products.error != null && products.items.isEmpty) {
      return ErrorView(
        message: products.error!,
        onRetry: () => ref
            .read(productsControllerProvider(ProductQuery(search: query))
                .notifier)
            .refresh(),
      );
    }

    if (products.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                color: Color(0xFF2A4A2A), size: 56),
            const SizedBox(height: 12),
            Text(
              'لا توجد نتائج لـ "$query"',
              style: const TextStyle(color: Color(0xFF5A7A5A), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            '${products.items.length} نتيجة',
            style: const TextStyle(color: Color(0xFF5A7A5A), fontSize: 13),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.66,
            ),
            itemCount: products.items.length,
            itemBuilder: (context, i) {
              final p = products.items[i];
              return ProductCard(
                product: p,
                onTap: () => context.push('/product/${p.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
