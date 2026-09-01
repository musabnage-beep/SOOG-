import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/cart_controller.dart';
import '../../providers/catalog_providers.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/product_card.dart';
import '../../widgets/state_views.dart';

class ProductsArgs {
  const ProductsArgs({
    this.categoryId,
    this.categorySlug,
    this.search,
    this.title,
  });

  final String? categoryId;
  final String? categorySlug;
  final String? search;
  final String? title;
}

const _sortOptions = <String, String>{
  'newest': 'الأحدث',
  'price_asc': 'الأقل سعراً',
  'price_desc': 'الأعلى سعراً',
  'name': 'الاسم',
};

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key, this.args});

  final ProductsArgs? args;

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  late ProductQuery _query;
  late bool _searchOpen;

  @override
  void initState() {
    super.initState();
    _query = ProductQuery(
      categoryId: widget.args?.categoryId,
      categorySlug: widget.args?.categorySlug,
      search: widget.args?.search,
    );
    _searchCtrl.text = widget.args?.search ?? '';
    _searchOpen = _searchCtrl.text.isNotEmpty;
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      ref.read(productsControllerProvider(_query).notifier).loadMore();
    }
  }

  void _applySearch(String value) {
    setState(() {
      _query = _query.copyWith(
        search: value.trim().isEmpty ? null : value.trim(),
        clearSearch: value.trim().isEmpty,
      );
    });
  }

  void _applySort(String sort) =>
      setState(() => _query = _query.copyWith(sort: sort));

  /// Builds a fresh query instead of `copyWith`, because the screen can be
  /// opened by slug and a leftover slug would fight the newly picked id.
  void _applyCategory(String? id) => setState(() {
    _query = ProductQuery(
      categoryId: id,
      search: _query.search,
      sort: _query.sort,
    );
  });

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsControllerProvider(_query));
    final title = widget.args?.title ?? 'المنتجات';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(_searchOpen ? Icons.search_off : Icons.search),
            onPressed: () {
              setState(() => _searchOpen = !_searchOpen);
              if (!_searchOpen && _searchCtrl.text.isNotEmpty) {
                _searchCtrl.clear();
                _applySearch('');
              }
            },
          ),
          PopupMenuButton<String>(
            color: AppColors.surface,
            icon: const Icon(Icons.tune),
            onSelected: _applySort,
            itemBuilder: (_) => _sortOptions.entries
                .map(
                  (e) => PopupMenuItem(
                    value: e.key,
                    child: Row(
                      children: [
                        if (_query.sort == e.key)
                          const Icon(
                            Icons.check,
                            size: 18,
                            color: AppColors.primary,
                          )
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Text(e.value),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (_searchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: _applySearch,
                decoration: InputDecoration(
                  hintText: 'ابحث...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchCtrl.clear();
                            _applySearch('');
                          },
                        ),
                ),
              ),
            ),
          _CategoryTabs(query: _query, onSelected: _applyCategory),
          Expanded(child: _body(state)),
        ],
      ),
      bottomNavigationBar: const _ViewCartBar(),
    );
  }

  Widget _body(ProductsState state) {
    if (state.isLoading) return const AppLoader();
    if (state.error != null && state.items.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () =>
            ref.read(productsControllerProvider(_query).notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return const EmptyView(
        icon: Icons.search_off,
        title: 'لا توجد نتائج',
        subtitle: 'جرّب كلمات بحث أخرى',
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () =>
          ref.read(productsControllerProvider(_query).notifier).refresh(),
      child: GridView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.66,
        ),
        itemCount: state.items.length + (state.isLoadingMore ? 2 : 0),
        itemBuilder: (context, i) {
          if (i >= state.items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = state.items[i];
          return FadeSlideIn(
            index: i,
            child: ProductCard(
              product: p,
              onTap: () => context.push('/product/${p.id}'),
            ),
          );
        },
      ),
    );
  }
}

/// Horizontal category chips above the grid. Categories are flat, so this is
/// simply the whole list with «الكل» in front.
class _CategoryTabs extends ConsumerWidget {
  const _CategoryTabs({required this.query, required this.onSelected});

  final ProductQuery query;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull;
    if (categories == null || categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _Chip(
              label: 'الكل',
              selected: query.categoryId == null && query.categorySlug == null,
              onTap: () => onSelected(null),
            );
          }
          final c = categories[i - 1];
          // The screen can be entered by slug, so match either identifier.
          final selected =
              query.categoryId == c.id || query.categorySlug == c.slug;
          return _Chip(
            label: c.nameAr,
            selected: selected,
            onTap: () => onSelected(c.id),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.onPrimary : AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating summary that appears once the cart has something in it, so the
/// customer can keep browsing and still see what they have picked.
class _ViewCartBar extends ConsumerWidget {
  const _ViewCartBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cartControllerProvider);
    if (state.count == 0) return const SizedBox.shrink();

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/cart'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${state.count}',
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'عرض السلة',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  Formatters.money(state.subtotal),
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
