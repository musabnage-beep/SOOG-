import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/catalog_providers.dart';
import '../../widgets/product_card.dart';
import '../../widgets/state_views.dart';

class ProductsArgs {
  const ProductsArgs({this.categoryId, this.categorySlug, this.search, this.title});

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

  @override
  void initState() {
    super.initState();
    _query = ProductQuery(
      categoryId: widget.args?.categoryId,
      categorySlug: widget.args?.categorySlug,
      search: widget.args?.search,
    );
    _searchCtrl.text = widget.args?.search ?? '';
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

  void _applySort(String sort) => setState(() => _query = _query.copyWith(sort: sort));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsControllerProvider(_query));
    final title = widget.args?.title ?? 'المنتجات';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
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
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune, color: AppColors.primary),
                  ),
                  onSelected: _applySort,
                  itemBuilder: (_) => _sortOptions.entries
                      .map((e) => PopupMenuItem(
                            value: e.key,
                            child: Row(
                              children: [
                                if (_query.sort == e.key)
                                  const Icon(Icons.check,
                                      size: 18, color: AppColors.primary)
                                else
                                  const SizedBox(width: 18),
                                const SizedBox(width: 8),
                                Text(e.value),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          Expanded(child: _body(state)),
        ],
      ),
    );
  }

  Widget _body(ProductsState state) {
    if (state.isLoading) return const AppLoader();
    if (state.error != null && state.items.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () => ref.read(productsControllerProvider(_query).notifier).refresh(),
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
      onRefresh: () => ref.read(productsControllerProvider(_query).notifier).refresh(),
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
          return ProductCard(
            product: p,
            onTap: () => context.push('/product/${p.id}'),
          );
        },
      ),
    );
  }
}
