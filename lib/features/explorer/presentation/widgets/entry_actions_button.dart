import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:file_explorer/features/transfers/presentation/transfer_visuals.dart';
import 'package:flutter/material.dart';
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
    builder: (context) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(iconForFileSystemEntryType(entry.type)),
              title: Text(entry.name),
              subtitle: Text(typeLabelForFileSystemEntry(entry)),
            ),
            const Divider(),
            _PropertyRow(label: 'Path', value: entry.path),
            _PropertyRow(
              label: 'Modified',
              value: formatFileModifiedAt(entry.modifiedAt),
            ),
            _PropertyRow(label: 'Size', value: detailForFileSystemEntry(entry)),
          ],
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
