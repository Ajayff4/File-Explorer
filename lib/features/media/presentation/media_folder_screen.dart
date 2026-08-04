import 'dart:io';

import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/media/presentation/media_viewer_screen.dart';
import 'package:file_explorer/features/media/presentation/widgets/media_thumbnail.dart';
import 'package:file_explorer/features/media/presentation/media_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

class MediaFolderScreen extends StatelessWidget {
  const MediaFolderScreen({
    required this.folderPath,
    required this.kind,
    super.key,
  });

  final String folderPath;
  final MediaLibraryKind kind;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(p.basename(folderPath)),
      ),
      body: _MediaFolderGrid(
        key: ValueKey(folderPath),
        folderPath: folderPath,
        kind: kind,
      ),
    );
  }
}

class _MediaFolderGrid extends StatefulWidget {
  const _MediaFolderGrid({
    required this.folderPath,
    required this.kind,
    super.key,
  });

  final String folderPath;
  final MediaLibraryKind kind;

  @override
  State<_MediaFolderGrid> createState() => _MediaFolderGridState();
}

class _MediaFolderGridState extends State<_MediaFolderGrid> {
  List<FileSystemEntry> _entries = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void didUpdateWidget(covariant _MediaFolderGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.folderPath != widget.folderPath || oldWidget.kind != widget.kind) {
      setState(() {
        _loading = true;
        _error = null;
        _entries = [];
      });
      _loadEntries();
    }
  }

  Future<void> _loadEntries() async {
    try {
      final dir = Directory(widget.folderPath);
      final entries = await dir.list().toList();
      final mediaEntries = <FileSystemEntry>[];

      for (final entity in entries) {
        if (entity is File) {
          final name = entity.uri.pathSegments.last;
          if (name.startsWith('.')) {
            continue;
          }
          final stat = await entity.stat();
          final type = _typeForExtension(entity.path);
          if (type == widget.kind.type) {
            mediaEntries.add(
              FileSystemEntry(
                name: name,
                path: entity.path,
                type: type,
                modifiedAt: stat.modified,
                sizeBytes: stat.size,
              ),
            );
          }
        } else if (entity is Directory) {
          final name = entity.uri.pathSegments.last;
          if (name.startsWith('.')) {
            continue;
          }
        }
      }

      mediaEntries.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

      if (mounted) {
        setState(() {
          _entries = mediaEntries;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  FileSystemEntryType _typeForExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (widget.kind.type == FileSystemEntryType.image) {
      const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg', 'heic', 'heif'};
      return imageExts.contains(ext) ? FileSystemEntryType.image : FileSystemEntryType.other;
    }
    if (widget.kind.type == FileSystemEntryType.video) {
      const videoExts = {'mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm', 'm4v', '3gp'};
      return videoExts.contains(ext) ? FileSystemEntryType.video : FileSystemEntryType.other;
    }
    return widget.kind.type;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            const Text('Failed to load folder'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadEntries();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Text('No ${widget.kind.label.toLowerCase()} found'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = (constraints.maxWidth / 92).floor().clamp(3, 6);

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
          itemCount: _entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemBuilder: (context, index) {
            final entry = _entries[index];
            return _MediaGridTile(
              entry: entry,
              onTap: () => _openMedia(context, entry),
            );
          },
        );
      },
    );
  }

  void _openMedia(BuildContext context, FileSystemEntry entry) {
    context.push(
      AppRoutes.mediaViewer,
      extra: MediaViewerSession(entry: entry, entries: _entries),
    );
  }
}

class _MediaGridTile extends StatelessWidget {
  const _MediaGridTile({
    required this.entry,
    required this.onTap,
  });

  final FileSystemEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: ClipRect(
          child: AspectRatio(
            aspectRatio: 1,
            child: MediaThumbnail(
              entry: entry,
              fallback: fileIconForEntry(context, entry),
              dimension: 120,
            ),
          ),
        ),
      ),
    );
  }
}
