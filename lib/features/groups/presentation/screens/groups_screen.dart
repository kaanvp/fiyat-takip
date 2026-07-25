import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/providers.dart';
import '../../../products/domain/entities/product_group.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../../../shared/widgets/ui/empty_state.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = ref.watch(appLocalizationsProvider);
    final groupsAsync = ref.watch(productGroupsProvider);
    final productsAsync = ref.watch(productsListProvider);

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
        title: Text(l10n.translate('myGroups')),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupDialog(l10n),
        icon: const Icon(Icons.add),
        label: Text(l10n.translate('createGroup')),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('${l10n.translate('somethingWentWrong')}: $error'),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return EmptyState(
              icon: Icons.folder_outlined,
              title: l10n.translate('noGroups'),
              message: l10n.translate('noGroupsMessage'),
              actionLabel: l10n.translate('createGroup'),
              onAction: () => _showCreateGroupDialog(l10n),
            );
          }
          return _buildGroupsList(theme, l10n, groups, productsAsync);
        },
      ),
    );
  }

  Widget _buildGroupsList(
    ThemeData theme,
    AppLocalizations l10n,
    List<ProductGroup> groups,
    AsyncValue<List<dynamic>> productsAsync,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(productGroupsProvider);
        ref.invalidate(productsListProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return _buildGroupCard(theme, l10n, group);
        },
      ),
    );
  }

  Widget _buildGroupCard(ThemeData theme, AppLocalizations l10n, ProductGroup group) {
    // Get product count for this group
    final productCountAsync = ref.watch(productsByGroupProvider(group.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => context.go('/group/${group.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Group icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.folder,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Group info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      productCountAsync.when(
                        data: (products) => Text(
                          '${products.length} ${l10n.translate('products')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        loading: () => Text(
                          '... ${l10n.translate('products')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Arrow icon
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateGroupDialog(AppLocalizations l10n) async {
    final nameController = TextEditingController();

    final groupName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.translate('createGroup')),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: l10n.translate('groupName'),
            hintText: l10n.translate('groupNameHint'),
          ),
          autofocus: true,
          onSubmitted: (value) => dialogContext.pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: Text(l10n.translate('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                dialogContext.pop(nameController.text.trim());
              }
            },
            child: Text(l10n.translate('createGroup')),
          ),
        ],
      ),
    );

    if (groupName != null && groupName.isNotEmpty) {
      try {
        final repository = ref.read(productRepositoryProvider);
        await repository.createGroup(ProductGroup(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: groupName,
        ));
        ref.invalidate(productGroupsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('groupCreated'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create group: $e')),
          );
        }
      }
    }
  }
}
