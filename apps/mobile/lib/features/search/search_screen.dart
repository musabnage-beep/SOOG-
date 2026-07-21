import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/catalog_providers.dart';
import '../../widgets/product_card.dart';
import '../../widgets/state_views.dart';

const _kHistoryKey = 'search_history';
const _kMaxHistory = 10;

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
// Search screen — live (debounced) search-as-you-type
// ─────────────────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Open the keyboard immediately, like a dedicated search screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Reflect the clear (×) button instantly, then debounce the actual query.
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final trimmed = value.trim();
      if (trimmed == _query) return;
      setState(() => _query = trimmed);
    });
  }

  void _submit(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    setState(() => _query = trimmed);
    if (trimmed.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).add(trimmed);
    }
  }

  void _runSearch(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    _submit(query);
    _focus.unfocus();
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _query = '');
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: BackButton(
          color: AppColors.dark,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              cursorColor: AppColors.primary,
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              onChanged: _onChanged,
              onSubmitted: _submit,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'ابحث عن منتج...',
                hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.muted, size: 20),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        splashRadius: 18,
                        icon: const Icon(Icons.close,
                            color: AppColors.muted, size: 18),
                        onPressed: _clear,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? _SuggestionsView(onSelect: _runSearch)
          : _ResultsView(query: _query),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state — recent searches + category suggestions
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionsView extends ConsumerWidget {
  const _SuggestionsView({required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(searchHistoryProvider);
    final categories = ref.watch(categoriesProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'عمليات البحث الأخيرة',
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: history
                .map(
                  (q) => _RecentChip(
                    label: q,
                    onTap: () => onSelect(q),
                    onDelete: () =>
                        ref.read(searchHistoryProvider.notifier).remove(q),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
        ],
        const Text(
          'تصفّح حسب القسم',
          style: TextStyle(
            color: AppColors.dark,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        categories.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 24),
            child: AppLoader(),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (items) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (c) => _SuggestChip(
                    label: c.nameAr,
                    onTap: () => onSelect(c.nameAr),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 40),
        if (history.isEmpty)
          const Center(
            child: Column(
              children: [
                Icon(Icons.search_rounded,
                    color: AppColors.border, size: 56),
                SizedBox(height: 12),
                Text(
                  'ابحث عن أي منتج تريده',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentChip extends StatelessWidget {
  const _RecentChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 15, color: AppColors.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: AppColors.dark, fontSize: 13),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, size: 15, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestChip extends StatelessWidget {
  const _SuggestChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search results grid (live)
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsView extends ConsumerWidget {
  const _ResultsView({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(
      productsControllerProvider(ProductQuery(search: query)),
    );

    if (products.isLoading && products.items.isEmpty) {
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
                color: AppColors.border, size: 56),
            const SizedBox(height: 12),
            Text(
              'لا توجد نتائج لـ "$query"',
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'جرّب كلمة أخرى',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '${products.items.length} نتيجة',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
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
