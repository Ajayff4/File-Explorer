import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/entry_actions_button.dart';
import 'package:file_explorer/features/search/presentation/controllers/file_search_controller.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SelectionBottomBar extends ConsumerWidget {
  const SelectionBottomBar({
    required this.selectedPaths,
    required this.onExitSelection,
    super.key,
  });

  final List<String> selectedPaths;
  final VoidCallback onExitSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transferController = ref.read(transferControllerProvider.notifier);
    final selectedCount = selectedPaths.length;
    final displayName =
        selectedCount == 1 ? selectedPaths.first : '$selectedCount items';

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                tooltip: 'Copy',
                icon: Icons.copy_rounded,
                onTap: () {
                  transferController.queueOperation(
                    operation: TransferOperation.copy,
                    sourcePaths: selectedPaths,
                    displayName: displayName,
                  );
                  _showQueuedSnackBar(context, TransferOperation.copy);
                  onExitSelection();
                },
              ),
              _ActionButton(
                tooltip: 'Cut',
                icon: Icons.content_cut_rounded,
                onTap: () {
                  transferController.queueOperation(
                    operation: TransferOperation.move,
                    sourcePaths: selectedPaths,
                    displayName: displayName,
                  );
                  _showQueuedSnackBar(context, TransferOperation.move);
                  onExitSelection();
                },
              ),
              _ActionButton(
                tooltip: 'Delete',
                icon: Icons.delete_rounded,
                onTap: () {
                  transferController.queueOperation(
                    operation: TransferOperation.delete,
                    sourcePaths: selectedPaths,
                    displayName: displayName,
                  );
                  _showQueuedSnackBar(context, TransferOperation.delete);
                  onExitSelection();
                },
              ),
              _ActionButton(
                tooltip: 'Rename',
                icon: Icons.edit_rounded,
                enabled: selectedCount == 1,
                onTap: () {
                  if (selectedCount != 1) return;
                  _showRenameDialog(
                    context,
                    transferController,
                    selectedPaths.first,
                    onExitSelection,
                  );
                },
              ),
              _ActionButton(
                tooltip: 'More',
                icon: Icons.more_horiz_rounded,
                onTap: () {
                  _showMoreOptions(
                    context,
                    ref,
                    selectedPaths,
                    displayName,
                    onExitSelection,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: tooltip,
      onPressed: enabled ? onTap : null,
      icon: Icon(icon),
    );
  }
}

Future<void> _showRenameDialog(
  BuildContext context,
  TransferController transferController,
  String path,
  VoidCallback onExitSelection,
) async {
  final name = path.split('/').last;
  final newName = await showDialog<String>(
    context: context,
    builder: (context) {
      return _RenameDialog(initialName: name);
    },
  );

  final trimmedName = newName?.trim();
  if (trimmedName == null || trimmedName.isEmpty || trimmedName == name) {
    return;
  }

  final parentPath = path.substring(0, path.length - name.length - 1);
  final newPath = '$parentPath/$trimmedName';

  transferController.queueOperation(
    operation: TransferOperation.rename,
    sourcePaths: [path],
    displayName: name,
    destinationPath: newPath,
  );
  if (!context.mounted) return;
  _showQueuedSnackBar(context, TransferOperation.rename);
  onExitSelection();
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename'),
      content: TextField(
        controller: _controller,
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
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Queue'),
        ),
      ],
    );
  }
}

void _showQueuedSnackBar(BuildContext context, TransferOperation operation) {
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

void _showMoreOptions(
  BuildContext context,
  WidgetRef ref,
  List<String> selectedPaths,
  String displayName,
  VoidCallback onExitSelection,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _shareSelected(context, selectedPaths);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_rounded),
              title: const Text('Compress'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final transferController =
                    ref.read(transferControllerProvider.notifier);
                final queued = await showCompressOptionsSheet(
                  context: context,
                  transferController: transferController,
                  sourcePaths: selectedPaths,
                  displayName: displayName,
                  destinationDirectory: _commonParentPath(selectedPaths),
                );
                if (queued) {
                  onExitSelection();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Properties'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showProperties(context, ref, selectedPaths);
              },
            ),
          ],
        ),
      );
    },
  );
}

void _shareSelected(BuildContext context, List<String> paths) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Share not yet implemented')),
  );
}

void _showProperties(BuildContext context, WidgetRef ref, List<String> paths) {
  if (paths.isEmpty) return;

  final explorerState = ref.read(explorerControllerProvider);
  final listing = explorerState.listing.valueOrNull;
  final searchState = ref.read(fileSearchControllerProvider);

  final allEntries = [
    ...?listing?.entries,
    ...searchState.results.map((r) => r.entry),
  ];

  final entries = <FileSystemEntry>[];
  for (final path in paths) {
    final match = allEntries.where((e) => e.path == path);
    if (match.isNotEmpty) {
      entries.add(match.first);
    }
  }

  if (entries.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${paths.length} items selected')),
    );
    return;
  }

  final volume = listing?.volume;
  showEntryProperties(context, entries, volume);
}

String _commonParentPath(List<String> paths) {
  if (paths.isEmpty) return '/';
  if (paths.length == 1) {
    final lastSlash = paths.first.lastIndexOf('/');
    return lastSlash > 0 ? paths.first.substring(0, lastSlash) : '/';
  }
  final first = paths.first;
  final last = paths.last;
  final commonLength = _commonPrefixLength(first, last);
  final common = first.substring(0, commonLength);
  final lastSlash = common.lastIndexOf('/');
  return lastSlash > 0 ? common.substring(0, lastSlash) : '/';
}

int _commonPrefixLength(String a, String b) {
  final minLength = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < minLength; i++) {
    if (a[i] != b[i]) return i;
  }
  return minLength;
}
