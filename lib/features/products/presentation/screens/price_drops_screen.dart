import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/app_bars/top_app_bar.dart';
import '../../../../shared/widgets/product/product_card.dart';
import '../../../../shared/widgets/ui/empty_state.dart';
import '../../domain/entities/product.dart';
import '../providers/product_providers.dart';

class PriceDropsScreen extends ConsumerStatefulWidget {
  const PriceDropsScreen({super.key});

  @override
  ConsumerState<PriceDropsScreen> createState() => _PriceDropsScreenState();
}

class _PriceDropsScreenState extends ConsumerState<PriceDropsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final productsAsync = ref.watch(productsListProvider);

    return Scaffold(
      appBar: TopAppBar(
        title: l10n.translate('priceDrops'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context, l10n);
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
          final priceDrops = products.where((p) => p.hasPriceDrop).toList();
          return _buildBody(l10n, priceDrops);
        },
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, List<Product> priceDrops) {
    // Apply search filter
    var filtered = priceDrops;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = priceDrops.where((p) =>
        p.name.toLowerCase().contains(query) ||
        p.displaySiteName.toLowerCase().contains(query) ||
        p.siteHost.toLowerCase().contains(query),
      ).toList();
    }

    if (filtered.isEmpty) {
      return _buildEmptyState(l10n, priceDrops.isNotEmpty);
    }
    return _buildPriceDropsList(filtered, l10n);
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool hasResultsWithoutFilter) {
    if (hasResultsWithoutFilter) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.translate('searchProducts'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.clear),
                label: Text(l10n.translate('cancel')),
              ),
            ],
          ),
        ),
      );
    }
    return EmptyState(
      icon: Icons.trending_down,
      title: l10n.translate('noPriceDrops'),
      message: l10n.translate('noPriceDropsMessage'),
    );
  }

  Widget _buildPriceDropsList(List<Product> priceDrops, AppLocalizations l10n) {
    return Column(
      children: [
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${priceDrops.length} ${l10n.translate('products')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.search, size: 16),
                  label: Text(_searchQuery, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _searchQuery = ''),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: priceDrops.length,
            itemBuilder: (context, index) {
              final product = priceDrops[index];
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

  void _showSearchDialog(BuildContext context, AppLocalizations l10n) {
    final searchController = TextEditingController(text: _searchQuery);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('searchProducts')),
        content: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: l10n.translate('searchProducts'),
            prefixIcon: const Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              setState(() => _searchQuery = value.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (searchController.text.trim().isNotEmpty) {
                setState(() => _searchQuery = searchController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text(l10n.translate('search')),
          ),
        ],
      ),
    );
  }
}
