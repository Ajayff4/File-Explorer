import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:file_explorer/features/transfers/presentation/transfer_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

class EntryActionsButton extends ConsumerWidget {
  const EntryActionsButton({required this.entry, super.key});

  final FileSystemEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'More',
      onPressed: () => _showEntryActions(context, ref, entry),
      icon: const Icon(Icons.more_vert_rounded),
    );
  }
}

void _showEntryActions(
  BuildContext context,
  WidgetRef ref,
  FileSystemEntry entry,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return _EntryActionsSheet(
        entry: entry,
        parentContext: context,
      );
    },
  );
}

class _EntryActionsSheet extends ConsumerWidget {
  const _EntryActionsSheet({
    required this.entry,
    required this.parentContext,
  });

  final FileSystemEntry entry;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(iconForFileSystemEntryType(entry.type)),
            title: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(detailForFileSystemEntry(entry)),
          ),
          const Divider(),
          for (final operation in [
            TransferOperation.copy,
            TransferOperation.move,
            TransferOperation.rename,
          ])
            ListTile(
              leading: Icon(iconForTransferOperation(operation)),
              title: Text(operation.label),
              onTap: () async {
                Navigator.of(context).pop();
                if (operation == TransferOperation.rename) {
                  await _requestRename(parentContext, ref, entry);
                } else {
                  _queueEntryOperation(parentContext, ref, entry, operation);
                }
              },
            ),
          ListTile(
            leading: Icon(
              iconForTransferOperation(TransferOperation.delete),
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              Navigator.of(context).pop();
              final shouldConfirm = ref
                  .read(settingsControllerProvider)
                  .settings
                  .confirmDestructiveActions;
              if (shouldConfirm) {
                await _confirmDelete(parentContext, ref, entry);
              } else {
                _queueEntryOperation(
                  parentContext,
                  ref,
                  entry,
                  TransferOperation.delete,
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Properties'),
            subtitle: Text(
              '${typeLabelForFileSystemEntry(entry)} - ${formatFileModifiedAt(entry.modifiedAt)}',
            ),
            onTap: () {
              Navigator.of(context).pop();
              _showEntryProperties(parentContext, entry);
            },
          ),
        ],
      ),
    );
  }
}

void _queueEntryOperation(
  BuildContext context,
  WidgetRef ref,
  FileSystemEntry entry,
  TransferOperation operation, {
  String? destinationPath,
}) {
  ref.read(transferControllerProvider.notifier).queueOperation(
        operation: operation,
        sourcePaths: [entry.path],
        displayName: entry.name,
        destinationPath: destinationPath,
        totalBytes: entry.sizeBytes,
      );
  _showQueuedSnackBar(context, operation);
}

Future<void> _requestRename(
  BuildContext context,
  WidgetRef ref,
  FileSystemEntry entry,
) async {
  final controller = TextEditingController(text: entry.name);
  final newName = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Queue'),
          ),
        ],
      );
    },
  );
  controller.dispose();

  final trimmedName = newName?.trim();
  if (trimmedName == null || trimmedName.isEmpty || trimmedName == entry.name) {
    return;
  }
  if (!context.mounted) {
    return;
  }

  _queueEntryOperation(
    context,
    ref,
    entry,
    TransferOperation.rename,
    destinationPath: p.join(p.dirname(entry.path), trimmedName),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  FileSystemEntry entry,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete'),
        content: Text('Queue delete for "${entry.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Queue'),
          ),
        ],
      );
    },
  );

  if (confirmed ?? false) {
    if (!context.mounted) {
      return;
    }
    _queueEntryOperation(context, ref, entry, TransferOperation.delete);
  }
}

void _showQueuedSnackBar(
  BuildContext context,
  TransferOperation operation,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${operation.label} task queued'),
      action: SnackBarAction(
        label: 'Transfers',
        onPressed: () => context.go(AppRoutes.transfers),
      ),
    ),
  );
}

void _showEntryProperties(BuildContext context, FileSystemEntry entry) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon and name
              Row(
                children: [
                  Icon(
                    iconForFileSystemEntryType(entry.type),
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          typeLabelForFileSystemEntry(entry),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Properties section
              _PropertiesSection(
                title: 'File Information',
                children: [
                  _PropertyRow(label: 'Type', value: typeLabelForFileSystemEntry(entry)),
                  if (entry.isFolder && entry.childrenCount != null)
                    _PropertyRow(label: 'Items', value: '${entry.childrenCount} items'),
                  if (!entry.isFolder && entry.sizeBytes != null)
                    _PropertyRow(label: 'Size', value: detailForFileSystemEntry(entry)),
                  _PropertyRow(
                    label: 'Modified',
                    value: formatFileModifiedAt(entry.modifiedAt),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              _PropertiesSection(
                title: 'Location',
                children: [
                  _PropertyRow(label: 'Path', value: entry.path),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Actions
              FilledButton.icon(
                onPressed: () {
                  _copyPathToClipboard(context, entry.path);
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy path'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close_rounded),
                label: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PropertiesSection extends StatelessWidget {
  const _PropertiesSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

void _copyPathToClipboard(BuildContext context, String path) {
  Clipboard.setData(ClipboardData(text: path));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Path copied to clipboard')),
  );
}
