import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/widgets/app_bars/top_app_bar.dart';
import '../../presentation/providers/product_providers.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String? initialUrl;

  const AddProductScreen({
    super.key,
    this.initialUrl,
  });

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _urlController = TextEditingController();
  final _targetPriceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _showGroupWarning = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _targetPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = ref.watch(appLocalizationsProvider);

    return Scaffold(
      appBar: TopAppBar(
        title: l10n.translate('addProduct'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Warning Banner
            if (_showGroupWarning)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.translate('similarProductWarning'),
                            style: theme.textTheme.bodySmall,
                          ),
                          TextButton(
                            onPressed: () {
                              // Show similar products
                            },
                            child: Text(l10n.translate('viewDetails')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // URL Input
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: l10n.translate('productUrl'),
                hintText: l10n.translate('urlHint'),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste),
                  onPressed: () {
                    // Paste from clipboard
                  },
                ),
              ),
              onChanged: (value) {
                // Check for similar products
                setState(() {
                  _showGroupWarning = value.isNotEmpty;
                });
              },
            ),
            const SizedBox(height: 24),
            // Preview Section
            if (_isLoading)
              _buildLoadingSkeleton(theme)
            else
              _buildPreviewSection(theme),
            const SizedBox(height: 24),
            // Target Price Input
            TextField(
              controller: _targetPriceController,
              decoration: InputDecoration(
                labelText: l10n.translate('targetPriceOptional'),
                hintText: l10n.translate('targetPriceHint'),
                prefixText: '₺',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            // Notes Input
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.translate('notesOptional'),
                hintText: l10n.translate('notesHint'),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            // Add Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isLoading ? null : _handleAddProduct,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.translate('addProduct')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(ThemeData theme) {
    final l10n = ref.watch(appLocalizationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('preview'),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              l10n.translate('enterUrlForPreview'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  void _handleAddProduct() {
    final l10n = ref.read(appLocalizationsProvider);

    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('pleaseEnterUrl'))),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _addProduct();
  }

  Future<void> _addProduct() async {
    final l10n = ref.read(appLocalizationsProvider);

    try {
      final repository = ref.read(productRepositoryProvider);
      final url = _urlController.text.trim();
      final targetPrice = double.tryParse(_targetPriceController.text.trim());
      final notes = _notesController.text.trim();

      await repository.addProductFromUrl(
        url,
        targetPrice: targetPrice,
        notes: notes.isNotEmpty ? notes : null,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('productAddedSuccess'))),
      );

      // Refresh products list and navigate back
      ref.invalidate(productsListProvider);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.go('/home');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.translate('failedToAddProduct')}$e')),
      );
    }
  }
}
