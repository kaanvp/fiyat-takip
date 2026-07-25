import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
  ConsumerState<GroupComparisonScreen> createState() =>
      _GroupComparisonScreenState();
}

class _GroupComparisonScreenState extends ConsumerState<GroupComparisonScreen> {
  bool _isEditingName = false;
  final TextEditingController _nameController = TextEditingController();
  String _groupName = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadGroupName();
  }

  Future<void> _loadGroupName() async {
    try {
      final repository = ref.read(productRepositoryProvider);
      final group = await repository.getGroupById(widget.groupId);
      if (group != null && mounted) {
        setState(() {
          _groupName = group.name;
          _nameController.text = group.name;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsByGroupProvider(widget.groupId));
    final l10n = ref.watch(appLocalizationsProvider);

    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('${l10n.translate('somethingWentWrong')}: $error'),
        ),
        data: (products) => _buildBody(l10n, products),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
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
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            _showSearchDialog();
          },
        ),
      ],
    );
  }

  Widget _buildEditableTitle() {
    final theme = Theme.of(context);
    if (_isEditingName) {
      return TextField(
        controller: _nameController,
        style: theme.textTheme.titleMedium,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        autofocus: true,
        onSubmitted: (value) => _updateGroupName(value),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isEditingName = true;
          _nameController.text = _groupName;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              _groupName.isNotEmpty ? _groupName : 'Group',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.edit, size: 16, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Future<void> _updateGroupName(String newName) async {
    if (newName.trim().isEmpty) {
      if (mounted) setState(() => _isEditingName = false);
      return;
    }
    try {
      final repository = ref.read(productRepositoryProvider);
      final group = await repository.getGroupById(widget.groupId);
      if (group != null) {
        await repository.updateGroup(group.copyWith(name: newName.trim()));
        if (mounted) {
          setState(() {
            _groupName = newName.trim();
            _isEditingName = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update group name: $e')),
        );
        setState(() => _isEditingName = false);
      }
    }
  }

  Widget _buildBody(AppLocalizations l10n, List<Product> products) {
    final theme = Theme.of(context);

    // Apply search filter
    var filteredProducts = products;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredProducts = products.where((p) =>
        p.name.toLowerCase().contains(query) ||
        p.displaySiteName.toLowerCase().contains(query) ||
        p.siteHost.toLowerCase().contains(query),
      ).toList();
    }

    // Find lowest price and cheapest product
    double? lowestPrice;
    String? cheapestProductId;
    if (filteredProducts.isNotEmpty) {
      Product cheapest = filteredProducts.first;
      for (final p in filteredProducts) {
        if (p.currentPrice < cheapest.currentPrice) cheapest = p;
      }
      lowestPrice = cheapest.currentPrice;
      cheapestProductId = cheapest.id;
    }

    // Determine currency symbol from first product
    final currencySymbol = products.isNotEmpty
        ? _currencySymbol(products.first.currency)
        : '₺';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Summary Header
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16, left: 4),
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
                    '${l10n.translate('lowest')}: $currencySymbol${_formatCompact(lowestPrice)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF16A34A),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Search query indicator
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 4),
              child: Row(
                children: [
                  Text(
                    '${filteredProducts.length} ${l10n.translate('products')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
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
          // Product Cards
          if (filteredProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48,
                      color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(
                      l10n.translate('searchProducts'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => setState(() => _searchQuery = ''),
                      icon: const Icon(Icons.clear, size: 18),
                      label: Text(l10n.translate('cancel')),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filteredProducts.map((product) {
              final isCheapest = product.id == cheapestProductId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildProductCard(
                  l10n,
                  product,
                  isCheapest: isCheapest,
                ),
              );
            }),
          // Add Link Button
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                context.go('/add-product?groupId=${widget.groupId}');
              },
              icon: const Icon(Icons.link, size: 20),
              label: Text(
                l10n.translate('addLink'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(
                  color: theme.colorScheme.primaryContainer,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    AppLocalizations l10n,
    Product product, {
    bool isCheapest = false,
  }) {
    final theme = Theme.of(context);
    final siteColor = _getSiteColor(product.siteHost);
    final hasDrop = product.hasPriceDrop;
    final currencySymbol = _currencySymbol(product.currency);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCheapest
              ? theme.colorScheme.primaryContainer
              : const Color(0xFFE7E5E4),
          width: isCheapest ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1C1917),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.go('/product/${product.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Cheapest ribbon badge
            if (isCheapest)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 12,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.translate('cheapest').toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: product.imageUrl != null &&
                              product.imageUrl!.isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress
                                                .expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress
                                                .expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.image_not_supported,
                                  size: 32,
                                );
                              },
                              headers: const {
                                'User-Agent':
                                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                              },
                            )
                          : const Icon(Icons.shopping_bag, size: 32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Site badge with colored dot
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
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                product.displaySiteName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Product name
                        Text(
                          product.name,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Price row
                        Row(
                          children: [
                            // Current price
                            Text(
                              '$currencySymbol${_formatCompact(product.currentPrice)}',
                              style: isCheapest
                                  ? theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme
                                          .colorScheme.primaryContainer,
                                    )
                                  : theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                            ),
                            if (hasDrop) ...[
                              const SizedBox(width: 8),
                              // Drop percentage badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A)
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.arrow_downward,
                                      size: 10,
                                      color: Color(0xFF16A34A),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${product.priceChangePercent.abs().toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Strikethrough original price
                        if (hasDrop)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '$currencySymbol${_formatCompact(product.initialPrice)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Open in new button
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      onPressed: () => _openProductUrl(product.productUrl),
                      icon: Icon(
                        Icons.open_in_new,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProductUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open link')),
          );
        }
      }
    }
  }

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'TRY':
      case 'TL':
        return '₺';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return '$currency ';
    }
  }

  String _formatCompact(double price) {
    if (price == price.roundToDouble()) {
      return price.toStringAsFixed(0);
    }
    return price.toStringAsFixed(2);
  }

  void _showSearchDialog() {
    final l10n = ref.read(appLocalizationsProvider);
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

  Color _getSiteColor(String siteHost) {
    final host = siteHost.toLowerCase();
    if (host.contains('trendyol')) return const Color(0xFFF97316);
    if (host.contains('hepsiburada')) return const Color(0xFF0284C7);
    if (host.contains('n11')) return const Color(0xFFDC2626);
    if (host.contains('amazon')) return const Color(0xFFF97316);
    if (host.contains('bestbuy')) return const Color(0xFF0284C7);
    if (host.contains('target')) return const Color(0xFFDC2626);
    if (host.contains('mediamarkt')) return const Color(0xFFFFD700);
    if (host.contains('vatan')) return const Color(0xFFDC2626);
    if (host.contains('teknos')) return const Color(0xFF0284C7);
    return Theme.of(context).colorScheme.primary;
  }
}
