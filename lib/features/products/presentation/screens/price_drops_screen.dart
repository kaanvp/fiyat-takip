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
              // Show search
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
    if (priceDrops.isEmpty) {
      return _buildEmptyState(l10n);
    }
    return _buildPriceDropsList(priceDrops);
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return EmptyState(
      icon: Icons.trending_down,
      title: l10n.translate('noPriceDrops'),
      message: l10n.translate('noPriceDropsMessage'),
    );
  }

  Widget _buildPriceDropsList(List<Product> priceDrops) {
    return ListView.builder(
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
    );
  }
}
