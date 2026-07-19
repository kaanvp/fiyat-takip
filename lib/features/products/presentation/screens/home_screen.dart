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
        data: (products) => products.isEmpty
            ? _buildEmptyState(l10n)
            : _buildProductList(products, l10n),
      ),
    );
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

  Widget _buildProductList(List<Product> products, AppLocalizations l10n) {
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
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                icon: const Icon(Icons.tune),
                onPressed: () {
                  // Show filter options
                },
              ),
            ],
          ),
        ),
        // Product List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
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
}
