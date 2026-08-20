import 'package:file_explorer/features/storage_permissions/domain/entities/storage_permission_state.dart';
import 'package:file_explorer/app/theme/neumorphic_card.dart';
import 'package:flutter/material.dart';

class StoragePermissionCard extends StatelessWidget {
  const StoragePermissionCard({
    required this.state,
    required this.onRequestFullAccess,
    required this.onRetry,
    super.key,
  });

  final StoragePermissionState state;
  final VoidCallback onRequestFullAccess;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final recoveryText = _recoveryTextFor(state);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: NeumorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder_special_rounded, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Storage access',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(state.message),
                const SizedBox(height: 10),
                Text(
                  'File Explorer needs explicit access before it can browse shared storage. You stay in control, and no broad permission is requested on launch.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (recoveryText != null) ...[
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              recoveryText,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (state.canRequestFullAccess)
                      FilledButton.icon(
                        onPressed: onRequestFullAccess,
                        icon: const Icon(Icons.admin_panel_settings_rounded),
                        label: Text(_primaryActionLabelFor(state)),
                      ),
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Check again'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _recoveryTextFor(StoragePermissionState state) {
  return switch (state.status) {
    StoragePermissionStatus.denied =>
      'Android will open the All files access screen. Enable File Explorer there, then return here and tap Check again.',
    StoragePermissionStatus.permanentlyDenied =>
      'Access is disabled in system settings. Open settings, enable All files access for File Explorer, then return and tap Check again.',
    StoragePermissionStatus.restricted =>
      'This device is restricting shared storage access. Check work profile, parental controls, or device policy settings.',
    _ => null,
  };
}

String _primaryActionLabelFor(StoragePermissionState state) {
  return switch (state.status) {
    StoragePermissionStatus.permanentlyDenied => 'Open settings',
    _ => 'Allow access',
  };
}
