import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SettingsSwitchTile(
            title: 'Show hidden files',
            subtitle: 'Include dotfiles and protected-looking folders',
            value: false,
          ),
          _SettingsSwitchTile(
            title: 'Confirm destructive actions',
            subtitle: 'Ask before delete, overwrite, or large moves',
            value: true,
          ),
          _SettingsSwitchTile(
            title: 'Remember network locations',
            subtitle: 'Keep LAN, FTP, and cloud targets in quick access',
            value: true,
          ),
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
  });

  final String title;
  final String subtitle;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: (_) {},
      ),
    );
  }
}
