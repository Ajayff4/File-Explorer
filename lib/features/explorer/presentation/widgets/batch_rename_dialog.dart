import 'dart:io';

import 'package:file_explorer/features/explorer/domain/batch_rename.dart';
import 'package:flutter/material.dart';

Future<BatchRenamePreview?> showBatchRenameDialog({
  required BuildContext context,
  required List<BatchRenameSource> sources,
}) {
  return showDialog<BatchRenamePreview>(
    context: context,
    builder: (context) => _BatchRenameDialog(sources: sources),
  );
}

class _BatchRenameDialog extends StatefulWidget {
  const _BatchRenameDialog({required this.sources});

  final List<BatchRenameSource> sources;

  @override
  State<_BatchRenameDialog> createState() => _BatchRenameDialogState();
}

class _BatchRenameDialogState extends State<_BatchRenameDialog> {
  final _findController = TextEditingController();
  final _replaceController = TextEditingController();
  final _prefixController = TextEditingController();
  final _suffixController = TextEditingController();
  final _startController = TextEditingController(text: '1');
  final _stepController = TextEditingController(text: '1');
  final _paddingController = TextEditingController(text: '2');

  var _numbered = false;
  var _preserveExtension = true;
  late BatchRenamePreview _preview;
  late List<String> _conflicts;

  @override
  void initState() {
    super.initState();
    _preview = _buildPreview();
    _conflicts = _findConflicts(_preview);
    for (final controller in _controllers) {
      controller.addListener(_refreshPreview);
    }
  }

  List<TextEditingController> get _controllers => [
        _findController,
        _replaceController,
        _prefixController,
        _suffixController,
        _startController,
        _stepController,
        _paddingController,
      ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  BatchRenamePreview _buildPreview() {
    return buildBatchRenamePreview(
      widget.sources,
      BatchRenameOptions(
        find: _findController.text,
        replace: _replaceController.text,
        prefix: _prefixController.text,
        suffix: _suffixController.text,
        numbered: _numbered,
        numberStart: int.tryParse(_startController.text) ?? 1,
        numberStep: int.tryParse(_stepController.text) ?? 1,
        numberPadding:
            (int.tryParse(_paddingController.text) ?? 2).clamp(0, 12),
        preserveExtension: _preserveExtension,
      ),
    );
  }

  void _refreshPreview() {
    if (!mounted) {
      return;
    }
    setState(() {
      _preview = _buildPreview();
      _conflicts = _findConflicts(_preview);
    });
  }

  List<String> _findConflicts(BatchRenamePreview preview) {
    final conflicts = <String>[];
    final sourcePaths = widget.sources.map((source) => source.path).toSet();
    for (final item in preview.changedItems) {
      if (sourcePaths.contains(item.newPath)) {
        conflicts.add(
          '"${item.oldName}" would overwrite another selected item',
        );
        continue;
      }
      try {
        final type = FileSystemEntity.typeSync(
          item.newPath,
          followLinks: false,
        );
        if (type != FileSystemEntityType.notFound) {
          conflicts.add('"${item.newName}" already exists');
        }
      } on FileSystemException {
        // Queueing the rename will surface any remaining filesystem errors.
      }
    }
    return conflicts;
  }

  bool get _canApply => _preview.canApply && _conflicts.isEmpty;

  @override
  Widget build(BuildContext context) {
    final errors = [..._preview.errors, ..._conflicts];
    final changedItems = _preview.changedItems;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              child: Row(
                children: [
                  const Icon(Icons.drive_file_rename_outline_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Batch rename',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _findController,
                      decoration: const InputDecoration(
                        labelText: 'Find',
                        hintText: 'Text to replace',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _replaceController,
                      decoration: const InputDecoration(
                        labelText: 'Replace with',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _prefixController,
                            decoration: const InputDecoration(
                              labelText: 'Prefix',
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _suffixController,
                            decoration: const InputDecoration(
                              labelText: 'Suffix',
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Number items'),
                      value: _numbered,
                      onChanged: (value) {
                        setState(() => _numbered = value);
                        _refreshPreview();
                      },
                    ),
                    if (_numbered)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _startController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Start',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _stepController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Step',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _paddingController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Padding',
                              ),
                            ),
                          ),
                        ],
                      ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Preserve file extension'),
                      subtitle: const Text(
                        'Keep text after the final dot unchanged',
                      ),
                      value: _preserveExtension,
                      onChanged: (value) {
                        setState(() => _preserveExtension = value);
                        _refreshPreview();
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preview',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (errors.isNotEmpty) ...[
                      _ErrorList(errors: errors),
                      const SizedBox(height: 12),
                    ],
                    if (changedItems.isEmpty)
                      Text(
                        'Set a pattern to preview renamed items.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      )
                    else ...[
                      for (final item in changedItems.take(8))
                        _PreviewRow(item: item),
                      if (changedItems.length > 8)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'and ${changedItems.length - 8} more',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _canApply
                        ? () => Navigator.of(context).pop(_preview)
                        : null,
                    child: Text(
                      changedItems.isEmpty
                          ? 'Queue renames'
                          : 'Queue ${changedItems.length} renames',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.item});

  final BatchRenameItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.oldName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              item.newName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorList extends StatelessWidget {
  const _ErrorList({required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final error in errors)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                error,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
