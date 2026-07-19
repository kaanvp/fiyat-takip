import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/providers.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/providers/product_providers.dart';

class GroupComparisonScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupComparisonScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<GroupComparisonScreen> createState() => _GroupComparisonScreenState();
}

class _GroupComparisonScreenState extends ConsumerState<GroupComparisonScreen> {
  bool _isEditingName = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = ref.watch(appLocalizationsProvider);
    final productsAsync = ref.watch(productsByGroupProvider(widget.groupId));

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
        title: _buildEditableTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality
            },
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('${l10n.translate('somethingWentWrong')}: $error'),
        ),
        data: (products) => _buildBody(theme, l10n, products),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n, List<Product> products) {
    final lowestPrice = products.isEmpty
        ? null
        : products.map((p) => p.currentPrice).reduce((a, b) => a < b ? a : b);

    return Column(
      children: [
        // Group Summary Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${l10n.translate('trackingRetailers')}${products.length} ${l10n.translate('retailers')}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (lowestPrice != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${l10n.translate('lowest')}: ₺${lowestPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Product Cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildGroupProductCard(context, products[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEditableTitle() {
    if (_isEditingName) {
      return TextField(
        controller: _nameController,
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        autofocus: true,
        onSubmitted: (value) {
          _updateGroupName(value);
        },
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            'Group',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: () {
            setState(() {
              _isEditingName = true;
            });
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Future<void> _updateGroupName(String newName) async {
    try {
      final repository = ref.read(productRepositoryProvider);
      final group = await repository.getGroupById(widget.groupId);
      if (group != null) {
        await repository.updateGroup(group.copyWith(name: newName));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update group name: $e')),
        );
      }
    }
    if (mounted) {
      setState(() {
        _isEditingName = false;
      });
    }
  }

  Widget _buildGroupProductCard(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final siteColor = _getSiteColor(product.siteHost);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          context.go('/product/${product.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_not_supported);
                          },
                        ),
                      )
                    : const Icon(Icons.shopping_bag),
              ),
              const SizedBox(width: 12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: siteColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          product.displaySiteName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Price with drop indicator
                    Row(
                      children: [
                        Text(
                          '₺${product.currentPrice.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (product.hasPriceDrop) ...[
                          Text(
                            '₺${product.initialPrice.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.trending_down,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.priceChangePercent.abs().toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSiteColor(String siteHost) {
    switch (siteHost.toLowerCase()) {
      case 'amazon.com':
      case 'amazon':
        return const Color(0xFFF97316);
      case 'bestbuy.com':
      case 'bestbuy':
        return const Color(0xFF0284C7);
      case 'target.com':
      case 'target':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF0F766E);
    }
  }
}
