import 'package:file_explorer/app/theme/app_theme.dart';
import 'package:file_explorer/features/settings/domain/entities/app_settings.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:file_explorer/app/theme/neumorphic_card.dart';
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
            title: 'Appearance',
            children: [
              _ThemeModeCard(
                mode: settings.themeMode,
                onChanged: controller.setThemeMode,
              ),
              _AccentPickerCard(
                accent: settings.themeAccent,
                onChanged: controller.setThemeAccent,
              ),
            ],
          ),
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

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({
    required this.mode,
    required this.onChanged,
  });

  final AppThemeMode mode;
  final ValueChanged<AppThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Theme mode'),
              subtitle: const Text('System, light, or dark appearance'),
            ),
            SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment(
                  value: AppThemeMode.system,
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: AppThemeMode.light,
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: AppThemeMode.dark,
                  label: Text('Dark'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) => onChanged(selection.first),
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentPickerCard extends StatelessWidget {
  const _AccentPickerCard({
    required this.accent,
    required this.onChanged,
  });

  final AppThemeAccent accent;
  final ValueChanged<AppThemeAccent> onChanged;

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Accent color'),
              subtitle: Text('Black & white theme variants share this accent'),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in AppThemeAccent.values)
                  _AccentSwatch(
                    accent: value,
                    selected: value == accent,
                    onTap: () => onChanged(value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final AppThemeAccent accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = appThemeSeed(accent);
    return Tooltip(
      message: accent.label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 3,
                  )
                : null,
          ),
          child: selected
              ? Icon(
                  Icons.check_rounded,
                  color: onAccent(appThemeSeed(accent)),
                  size: 24,
                )
              : null,
        ),
      ),
    );
  }
}

extension on AppThemeAccent {
  String get label => switch (this) {
        AppThemeAccent.purple => 'Purple',
        AppThemeAccent.green => 'Green',
        AppThemeAccent.pink => 'Pink',
        AppThemeAccent.red => 'Red',
        AppThemeAccent.royalBlue => 'Royal blue',
        AppThemeAccent.mint => 'Mint',
      };
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
      padding: const EdgeInsets.only(bottom: 24),
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
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            children[i],
          ],
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
    return NeumorphicCard(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
