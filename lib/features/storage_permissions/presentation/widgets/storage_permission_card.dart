import 'package:file_explorer/features/storage_permissions/domain/entities/storage_permission_state.dart';
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (state.canRequestFullAccess)
                      FilledButton.icon(
                        onPressed: onRequestFullAccess,
                        icon: const Icon(Icons.admin_panel_settings_rounded),
                        label: const Text('Allow access'),
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
