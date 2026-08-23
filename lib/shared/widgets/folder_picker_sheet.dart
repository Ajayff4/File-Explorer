import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/shared/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A bottom-sheet folder browser used to choose an output/save directory.
/// Extracted so every feature (downloader, nearby, QR generator, ...) shares
/// one implementation.
class FolderPickerSheet extends StatefulWidget {
  const FolderPickerSheet({
    required this.repository,
    required this.startPath,
    required this.onSelected,
    super.key,
  });

  final StorageRepository repository;
  final String startPath;
  final ValueChanged<String> onSelected;

  @override
  State<FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends State<FolderPickerSheet> {
  late String _currentPath;
  List<FileSystemEntry> _folders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.startPath;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _folders = [];
    });
    try {
      final listing = await widget.repository.listDirectory(_currentPath);
      if (!mounted) return;
      setState(() {
        _folders = listing.entries.where((entry) => entry.isFolder).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _createFolder() async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var input = '';
        return AlertDialog(
          title: const Text('New folder'),
          content: TextField(
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Folder name',
              hintText: 'e.g. My Folder',
            ),
            onChanged: (value) => input = value,
            onSubmitted: (value) =>
                Navigator.of(dialogContext).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(input.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty || !mounted) return;

    final path = _currentPath.endsWith('/')
        ? '$_currentPath$name'
        : '$_currentPath/$name';
    final created = await widget.repository.createFolder(path);
    if (!mounted) return;
    if (created) {
      setState(() => _currentPath = path);
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create that folder')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Up',
                  onPressed: _currentPath == _parent(_currentPath)
                      ? null
                      : () {
                          setState(() => _currentPath = _parent(_currentPath));
                          _load();
                        },
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                IconButton(
                  tooltip: 'Create folder',
                  onPressed: _createFolder,
                  icon: const Icon(Icons.create_new_folder_rounded),
                ),
                Expanded(
                  child: Text(
                    _currentPath,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onSelected(_currentPath),
                  child: const Text('Use folder'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const AppLoadingIndicator()
                : _folders.isEmpty
                    ? const Center(child: Text('No sub-folders'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: _folders.length,
                        itemBuilder: (context, index) {
                          final folder = _folders[index];
                          return InkWell(
                            onTap: () {
                              setState(() => _currentPath = folder.path);
                              _load();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: scheme.outline),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.folder_rounded),
                                  const SizedBox(height: 6),
                                  Text(
                                    folder.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _parent(String path) {
    if (path == '/' || path.isEmpty) return '/';
    final index = path.lastIndexOf('/');
    return index <= 0 ? '/' : path.substring(0, index);
  }
}

/// Shows [FolderPickerSheet] seeded from [currentPath] and returns the chosen
/// directory (or null if cancelled).
Future<String?> pickFolder(
  BuildContext context,
  WidgetRef ref, {
  required String currentPath,
}) async {
  final repository = ref.read(storageRepositoryProvider);
  var start = currentPath;
  if (start.isEmpty) {
    final volumes = await repository.getStorageVolumes();
    start = volumes.isEmpty ? '/' : volumes.first.path;
  }
  if (!context.mounted) return null;
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: FolderPickerSheet(
        repository: repository,
        startPath: start,
        onSelected: (path) => Navigator.of(sheetContext).pop(path),
      ),
    ),
  );
}
