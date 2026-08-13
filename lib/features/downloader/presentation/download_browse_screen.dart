import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/downloader/presentation/download_entry_grid.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/entry_actions_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

class DownloadBrowseScreen extends ConsumerStatefulWidget {
  const DownloadBrowseScreen({required this.startPath, super.key});

  final String startPath;

  @override
  ConsumerState<DownloadBrowseScreen> createState() =>
      _DownloadBrowseScreenState();
}

class _DownloadBrowseScreenState extends ConsumerState<DownloadBrowseScreen> {
  late String _currentPath;
  List<FileSystemEntry> _entries = [];
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
      _entries = [];
    });
    try {
      final listing = await ref
          .read(storageRepositoryProvider)
          .listDirectory(_currentPath);
      if (!mounted) {
        return;
      }
      setState(() {
        _entries = listing.entries
          ..sort((a, b) {
            if (a.isFolder != b.isFolder) {
              return a.isFolder ? -1 : 1;
            }
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    }
  }

  void _openEntry(FileSystemEntry entry) {
    if (entry.isFolder) {
      setState(() => _currentPath = entry.path);
      _load();
      return;
    }
    openFileForPreview(
      context: context,
      ref: ref,
      entry: entry,
      playlist: _entries,
    );
  }

  void _navigateUp() {
    final parent = _parent(_currentPath);
    if (parent != _currentPath) {
      setState(() => _currentPath = parent);
      _load();
    }
  }

  String _parent(String path) {
    if (path == '/' || path.isEmpty) {
      return '/';
    }
    final index = path.lastIndexOf('/');
    return index <= 0 ? '/' : path.substring(0, index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.downloader);
            }
          },
        ),
        title: Text(p.basename(_currentPath)),
        actions: [
          IconButton(
            tooltip: 'Up',
            onPressed: _currentPath == _parent(_currentPath)
                ? null
                : _navigateUp,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('No items in this folder'))
              : DownloadEntryGrid(
                  entries: _entries,
                  onOpen: _openEntry,
                ),
    );
  }
}