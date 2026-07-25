import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/app_bars/top_app_bar.dart';
import '../../../../shared/widgets/product/product_card.dart';
import '../../../../shared/widgets/ui/empty_state.dart';
import '../../domain/entities/product.dart';
import '../../presentation/providers/product_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showPriceDropsOnly = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);
    final l10n = ref.watch(appLocalizationsProvider);

    return Scaffold(
      appBar: TopAppBar(
        title: l10n.translate('homeTitle'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: l10n.translate('myGroups'),
            onPressed: () {
              context.go('/groups');
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.go('/add-product');
            },
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.translate('somethingWentWrong'),
          message: error.toString(),
          actionLabel: l10n.translate('retry'),
          onAction: () => ref.invalidate(productsListProvider),
        ),
        data: (products) {
          final filtered = _filterProducts(products);
          return products.isEmpty
              ? _buildEmptyState(l10n)
              : _buildProductList(filtered, products.length, l10n);
        },
      ),
    );
  }

  List<Product> _filterProducts(List<Product> products) {
    var result = products;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      result = result.where((p) =>
        p.name.toLowerCase().contains(_searchQuery) ||
        p.displaySiteName.toLowerCase().contains(_searchQuery) ||
        p.siteHost.toLowerCase().contains(_searchQuery) ||
        p.tags.any((t) => t.toLowerCase().contains(_searchQuery)),
      ).toList();
    }

    // Filter by price drop
    if (_showPriceDropsOnly) {
      result = result.where((p) => p.hasPriceDrop).toList();
    }

    return result;
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return EmptyState(
      icon: Icons.shopping_bag,
      title: l10n.translate('nothingHereYet'),
      message: l10n.translate('noProductsMessage'),
      actionLabel: l10n.translate('addFirstProduct'),
      onAction: () {
        context.go('/add-product');
      },
    );
  }

  Widget _buildProductList(List<Product> filteredProducts, int totalCount, AppLocalizations l10n) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.translate('searchProducts'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                icon: Icon(
                  Icons.tune,
                  color: _showPriceDropsOnly
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: () {
                  _showFilterDialog(context, l10n);
                },
              ),
            ],
          ),
        ),
        if (_searchQuery.isNotEmpty || _showPriceDropsOnly)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${filteredProducts.length} / $totalCount ${l10n.translate('products')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (_showPriceDropsOnly)
                  Chip(
                    label: Text(
                      l10n.translate('showPriceDropsOnly'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _showPriceDropsOnly = false);
                    },
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        // Product List
        Expanded(
          child: filteredProducts.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate('noProductsMessage'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ProductCard(
                        product: product,
                        onTap: () {
                          context.go('/product/${product.id}');
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showFilterDialog(BuildContext context, AppLocalizations l10n) {
    bool localShowPriceDropsOnly = _showPriceDropsOnly;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.translate('filter')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('filterByPriceDrop'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: Text(l10n.translate('showPriceDropsOnly')),
                value: localShowPriceDropsOnly,
                onChanged: (value) {
                  setDialogState(() {
                    localShowPriceDropsOnly = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.translate('cancel')),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _showPriceDropsOnly = localShowPriceDropsOnly;
                });
                Navigator.pop(ctx);
              },
              child: Text(l10n.translate('apply')),
            ),
          ],
        ),
      ),
    );
  }
}
