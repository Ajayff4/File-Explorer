import 'package:file_explorer/features/settings/domain/entities/app_settings.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final settings = state.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            tooltip: 'Reset settings',
            onPressed: controller.resetSettings,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.isLoading) const LinearProgressIndicator(),
          _SettingsSection(
            title: 'Explorer',
            children: [
              _SettingsSwitchTile(
                title: 'Show hidden files',
                subtitle: 'Include dotfiles and protected-looking folders',
                value: settings.showHiddenFiles,
                onChanged: (value) => controller.setBool(
                  SettingKey.showHiddenFiles,
                  value,
                ),
              ),
              _SettingsSwitchTile(
                title: 'Folders only in history',
                subtitle: 'Keep recent history focused on folders',
                value: settings.showFoldersOnlyInHistory,
                onChanged: (value) => controller.setBool(
                  SettingKey.showFoldersOnlyInHistory,
                  value,
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Transfers',
            children: [
              _SettingsSwitchTile(
                title: 'Confirm destructive actions',
                subtitle: 'Ask before delete, overwrite, or large moves',
                value: settings.confirmDestructiveActions,
                onChanged: (value) => controller.setBool(
                  SettingKey.confirmDestructiveActions,
                  value,
                ),
              ),
              _SettingsSwitchTile(
                title: 'Display transfer station',
                subtitle: 'Keep transfer status visible in the app',
                value: settings.showTransferStation,
                onChanged: (value) => controller.setBool(
                  SettingKey.showTransferStation,
                  value,
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Search',
            children: [
              _SettingsSwitchTile(
                title: 'Use indexed search',
                subtitle:
                    'Reuse stored search indexes for faster repeat search',
                value: settings.useIndexedSearch,
                onChanged: (value) => controller.setBool(
                  SettingKey.useIndexedSearch,
                  value,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
