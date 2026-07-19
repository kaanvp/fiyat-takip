import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/app_bars/top_app_bar.dart';
import '../../../../shared/widgets/settings/settings_tile.dart';
import '../../../../shared/widgets/settings/settings_section.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/background/background_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _checkFrequency = '6 hours';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: TopAppBar(
        title: l10n.translate('settings'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Section
          SettingsSection(
            title: l10n.translate('language'),
            children: [
              SettingsTile(
                title: l10n.translate('language'),
                subtitle: l10n.translate('languageSub'),
                trailing: Text(
                  currentLocale.languageCode == 'tr'
                      ? l10n.translate('turkish')
                      : l10n.translate('english'),
                ),
                onTap: _showLanguageDialog,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: l10n.translate('notifications'),
            children: [
              SettingsTile(
                title: l10n.translate('enableNotifications'),
                subtitle: l10n.translate('enableNotificationsSub'),
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _toggleBackgroundTasks(value);
                  },
                ),
              ),
              SettingsTile(
                title: l10n.translate('checkFrequency'),
                subtitle: l10n.translate('checkFrequencySub'),
                trailing: Text(_checkFrequency),
                onTap: () {
                  _showFrequencyDialog();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: l10n.translate('data'),
            children: [
              SettingsTile(
                title: l10n.translate('backupData'),
                subtitle: l10n.translate('backupDataSub'),
                trailing: _isLoading 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup),
                onTap: _isLoading ? null : _backupData,
              ),
              SettingsTile(
                title: l10n.translate('restoreData'),
                subtitle: l10n.translate('restoreDataSub'),
                trailing: _isLoading 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore),
                onTap: _isLoading ? null : _restoreData,
              ),
              SettingsTile(
                title: l10n.translate('clearAllData'),
                subtitle: l10n.translate('clearAllDataSub'),
                trailing: const Icon(Icons.delete_forever, color: Colors.red),
                onTap: _clearAllData,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: l10n.translate('about'),
            children: [
              SettingsTile(
                title: l10n.translate('version'),
                subtitle: '1.0.0',
                trailing: const Icon(Icons.info_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final l10n = ref.read(appLocalizationsProvider);
    final currentLocale = ref.read(localeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('English'),
              leading: Radio<String>(
                value: 'en',
                groupValue: currentLocale.languageCode,
                onChanged: (value) {
                  ref.read(localeProvider.notifier).state = const Locale('en', 'US');
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text('Türkçe'),
              leading: Radio<String>(
                value: 'tr',
                groupValue: currentLocale.languageCode,
                onChanged: (value) {
                  ref.read(localeProvider.notifier).state = const Locale('tr', 'TR');
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleBackgroundTasks(bool enabled) {
    // Toggle background task registration
    if (enabled) {
      BackgroundService.registerPeriodicTask(
        interval: _parseFrequencyToDuration(_checkFrequency),
      );
    } else {
      BackgroundService.cancelAllTasks();
    }
  }

  void _showFrequencyDialog() {
    final l10n = ref.read(appLocalizationsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('checkFrequency')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFrequencyOption(l10n.translate('hour')),
            _buildFrequencyOption(l10n.translate('hours3')),
            _buildFrequencyOption(l10n.translate('hours6')),
            _buildFrequencyOption(l10n.translate('hours12')),
            _buildFrequencyOption(l10n.translate('hours24')),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(String frequency) {
    return ListTile(
      title: Text(frequency),
      trailing: _checkFrequency == frequency 
          ? const Icon(Icons.check, color: Colors.green) 
          : null,
      onTap: () {
        setState(() {
          _checkFrequency = frequency;
        });
        Navigator.pop(context);
        if (_notificationsEnabled) {
          _toggleBackgroundTasks(true);
        }
      },
    );
  }

  Duration _parseFrequencyToDuration(String frequency) {
    switch (frequency) {
      case '1 hour':
      case '1 saat':
        return const Duration(hours: 1);
      case '3 hours':
      case '3 saat':
        return const Duration(hours: 3);
      case '6 hours':
      case '6 saat':
        return const Duration(hours: 6);
      case '12 hours':
      case '12 saat':
        return const Duration(hours: 12);
      case '24 hours':
      case '24 saat':
        return const Duration(hours: 24);
      default:
        return const Duration(hours: 6);
    }
  }

  Future<void> _backupData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(productRepositoryProvider);
      final jsonData = await repository.exportDataToJson();
      
      // Share the JSON file
      final l10n = ref.read(appLocalizationsProvider);

      await Share.share(
        jsonData,
        subject: 'PriceWatch Backup',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('backupCreated'))),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = ref.read(appLocalizationsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('backupFailed')}$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restoreData() async {
    // For now, show a message that this feature requires file picker
    // In a complete implementation, you would add file_picker to pubspec.yaml
    if (mounted) {
      final l10n = ref.read(appLocalizationsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('restoreRequiresFilePicker')),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    // Alternatively, you could implement clipboard-based import:
    // final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    // if (clipboardData != null && clipboardData.text != null) {
    //   await repository.importDataFromJson(clipboardData.text!);
    // }
  }

  Future<void> _clearAllData() async {
    final l10n = ref.read(appLocalizationsProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('clearAllDataTitle')),
        content: Text(l10n.translate('clearAllDataMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final repository = ref.read(productRepositoryProvider);
        await repository.clearAllData();
        
        if (mounted) {
          final l10n = ref.read(appLocalizationsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('dataCleared'))),
          );
        }
      } catch (e) {
        if (mounted) {
          final l10n = ref.read(appLocalizationsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.translate('failedToClearData')}$e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
