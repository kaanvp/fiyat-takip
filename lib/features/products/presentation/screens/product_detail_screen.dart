import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/providers.dart';
import '../../domain/entities/product.dart';
import '../providers/product_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = ref.watch(appLocalizationsProvider);
    final productAsync = ref.watch(productProvider(productId));

    return productAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('${l10n.translate('somethingWentWrong')}: $error'),
          ),
        ),
      ),
      data: (product) => _buildDetailScreen(context, ref, theme, l10n, product),
    );
  }

  Widget _buildDetailScreen(BuildContext context, WidgetRef ref, ThemeData theme, AppLocalizations l10n, Product product) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          product.name,
          style: theme.textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () async {
              final uri = Uri.parse(product.productUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            _buildHeroSection(context, product, theme, l10n),
            const SizedBox(height: 24),
            // Price History Chart
            _buildPriceHistorySection(theme, l10n),
            const SizedBox(height: 24),
            // Details Section
            _buildDetailsSection(context, product, theme, l10n),
            const SizedBox(height: 24),
            // Actions
            _buildActionsSection(context, product, theme, l10n, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, Product product, ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: product.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    product.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 64);
                    },
                  ),
                )
              : const Icon(Icons.shopping_bag, size: 64),
        ),
        const SizedBox(height: 16),
        // Site Badge and Status
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                product.displaySiteName.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (product.hasPriceDrop)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_down, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      l10n.translate('allTimeLow'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Product Name
        Text(
          product.name,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        // Price
        Row(
          children: [
            Text(
              '${product.currency}${product.currentPrice.toStringAsFixed(0)}',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${product.currency}${product.initialPrice.toStringAsFixed(0)}',
              style: theme.textTheme.titleMedium?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceHistorySection(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('priceHistory'),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Segmented Control
          Row(
            children: [
              Expanded(
                child: _buildSegmentButton(l10n.translate('days30'), true, theme),
              ),
              Expanded(
                child: _buildSegmentButton(l10n.translate('days90'), false, theme),
              ),
              Expanded(
                child: _buildSegmentButton(l10n.translate('allTime'), false, theme),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart Placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(l10n.translate('priceChartPlaceholder')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, bool isSelected, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isSelected
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, Product product, ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('details'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(l10n.translate('added'), _formatDate(product.addedAt, l10n), theme),
          _buildDetailRow(l10n.translate('lastChecked'), _formatDate(product.lastCheckedAt, l10n), theme),
          _buildDetailRow(l10n.translate('priceChange'), '${product.priceChangePercent.toStringAsFixed(1)}%', theme),
          if (product.targetPrice != null)
            _buildDetailRow(l10n.translate('targetPrice'), '${product.currency}${product.targetPrice}', theme),
          if (product.notes != null && product.notes!.isNotEmpty)
            _buildDetailRow(l10n.translate('notes'), product.notes!, theme),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, Product product, ThemeData theme, AppLocalizations l10n, WidgetRef ref) {
    return Column(
      children: [
        if (product.groupId != null) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                context.go('/group/${product.groupId}');
              },
              icon: const Icon(Icons.compare_arrows),
              label: Text(l10n.translate('comparePrices')),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () {
              // Edit product
              _showEditProductDialog(context, product, ref, l10n);
            },
            icon: const Icon(Icons.edit),
            label: Text(l10n.translate('editProduct')),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              _toggleArchiveProduct(context, product, ref, l10n);
            },
            icon: Icon(product.isArchived ? Icons.unarchive : Icons.archive),
            label: Text(product.isArchived ? l10n.translate('unarchive') : l10n.translate('archive')),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              _showDeleteDialog(context, product, ref, l10n);
            },
            icon: const Icon(Icons.delete),
            label: Text(l10n.translate('delete')),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, Product product, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.translate('deleteProduct')),
        content: Text('${l10n.translate('deleteConfirm')}${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(l10n.translate('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final repository = ref.read(productRepositoryProvider);
                await repository.deleteProduct(product.id);
                ref.invalidate(productsListProvider);
                if (dialogContext.mounted) {
                  dialogContext.pop();
                }
                if (context.mounted) {
                  context.pop();
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.translate('delete')),
          ),
        ],
      ),
    );
  }

  void _toggleArchiveProduct(BuildContext context, Product product, WidgetRef ref, AppLocalizations l10n) async {
    try {
      final repository = ref.read(productRepositoryProvider);
      if (product.isArchived) {
        await repository.unarchiveProduct(product.id);
      } else {
        await repository.archiveProduct(product.id);
      }
      ref.invalidate(productsListProvider);
      ref.invalidate(productProvider(productId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(product.isArchived
                ? 'Product unarchived'
                : 'Product archived'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to archive: $e')),
        );
      }
    }
  }

  void _showEditProductDialog(BuildContext context, Product product, WidgetRef ref, AppLocalizations l10n) async {
    final targetPriceController = TextEditingController(
      text: product.targetPrice?.toString() ?? '',
    );
    final notesController = TextEditingController(
      text: product.notes ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.translate('editProduct')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetPriceController,
              decoration: InputDecoration(
                labelText: l10n.translate('targetPriceOptional'),
                prefixText: '₺',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: l10n.translate('notesOptional'),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: Text(l10n.translate('cancel')),
          ),
          FilledButton(
            onPressed: () => dialogContext.pop(true),
            child: Text(l10n.translate('save')),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final repository = ref.read(productRepositoryProvider);
        final updatedProduct = product.copyWith(
          targetPrice: double.tryParse(targetPriceController.text),
          notes: notesController.text.isNotEmpty ? notesController.text : null,
        );
        await repository.updateProduct(updatedProduct);
        ref.invalidate(productsListProvider);
        ref.invalidate(productProvider(productId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime? date, AppLocalizations l10n) {
    if (date == null) return l10n.translate('never');
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${l10n.translate('minAgo')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${l10n.translate('hAgo')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${l10n.translate('dAgo')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
