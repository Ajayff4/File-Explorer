import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/shared/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A bottom-sheet browser used to choose a single file (for example a
/// cookies.txt export).
///
/// Mirrors [FolderPickerSheet] but also surfaces files: folders navigate,
/// files select. Extracted so any feature can reuse one implementation
/// instead of pulling in a platform file-picker plugin.
class FilePickerSheet extends StatefulWidget {
  const FilePickerSheet({
    required this.repository,
    required this.startPath,
    required this.onSelected,
    this.extensions = const [],
    super.key,
  });

  final StorageRepository repository;
  final String startPath;
  final ValueChanged<String> onSelected;

  /// Lowercase extensions to show, without a leading dot. Empty shows all.
  final List<String> extensions;

  @override
  State<FilePickerSheet> createState() => _FilePickerSheetState();
}

class _FilePickerSheetState extends State<FilePickerSheet> {
  late String _currentPath;
  List<FileSystemEntry> _folders = [];
  List<FileSystemEntry> _files = [];
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
      _files = [];
    });
    try {
      final listing = await widget.repository.listDirectory(_currentPath);
      if (!mounted) return;
      final folders = listing.entries.where((entry) => entry.isFolder).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      final files =
          listing.entries.where((entry) => !entry.isFolder && _matches(entry)).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        _folders = folders;
        _files = files;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool _matches(FileSystemEntry entry) {
    if (widget.extensions.isEmpty) {
      return true;
    }
    final name = entry.name.toLowerCase();
    return widget.extensions.any((ext) => name.endsWith('.$ext'));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
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
                Expanded(
                  child: Text(
                    _currentPath,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const AppLoadingIndicator()
                : _folders.isEmpty && _files.isEmpty
                    ? const Center(child: Text('No matching files'))
                    : ListView(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        children: [
                          for (final folder in _folders)
                            ListTile(
                              leading: const Icon(Icons.folder_rounded),
                              title: Text(folder.name),
                              onTap: () {
                                setState(() => _currentPath = folder.path);
                                _load();
                              },
                            ),
                          if (_folders.isNotEmpty && _files.isNotEmpty)
                            const Divider(height: 1),
                          for (final file in _files)
                            ListTile(
                              leading: const Icon(Icons.insert_drive_file_rounded),
                              title: Text(file.name),
                              onTap: () => widget.onSelected(file.path),
                            ),
                        ],
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

/// Shows [FilePickerSheet] seeded from [startPath] and returns the chosen file
/// path (or null if cancelled).
Future<String?> pickFile(
  BuildContext context,
  WidgetRef ref, {
  String startPath = '',
  List<String> extensions = const [],
}) async {
  final repository = ref.read(storageRepositoryProvider);
  var start = startPath;
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
      child: FilePickerSheet(
        repository: repository,
        startPath: start,
        extensions: extensions,
        onSelected: (path) => Navigator.of(sheetContext).pop(path),
      ),
    ),
  );
}
