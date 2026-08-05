import 'dart:io';

import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/explorer_screen.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/media/presentation/media_viewer_screen.dart';
import 'package:file_explorer/features/media/presentation/widgets/media_thumbnail.dart';
import 'package:file_explorer/features/media/presentation/media_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return BackButtonListener(
      onBackButtonPressed: () async {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.media(kind));
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.media(kind));
              }
            },
          ),
          title: Text(p.basename(folderPath)),
        ),
        body: _MediaFolderGrid(
          key: ValueKey(folderPath),
          folderPath: folderPath,
          kind: kind,
        ),
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
    if (oldWidget.folderPath != widget.folderPath ||
        oldWidget.kind != widget.kind) {
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
    const imageExts = {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'svg',
      'heic',
      'heif',
    };
    const videoExts = {
      'mp4',
      'avi',
      'mov',
      'mkv',
      'wmv',
      'flv',
      'webm',
      'm4v',
      '3gp',
    };
    const audioExts = {
      'mp3',
      'wav',
      'flac',
      'aac',
      'ogg',
      'wma',
      'm4a',
      'opus',
      'aiff',
    };
    const docExts = {
      'pdf',
      'doc',
      'docx',
      'odt',
      'rtf',
      'txt',
      'md',
      'log',
      'xls',
      'xlsx',
      'ods',
      'csv',
      'ppt',
      'pptx',
      'odp',
    };
    const archiveExts = {
      'zip',
      'rar',
      '7z',
      'tar',
      'gz',
      'bz2',
      'xz',
      'tgz',
      'tar.gz',
    };
    const appExts = {'apk', 'apks', 'xapk', 'apkm', 'aab'};

    return switch (ext) {
      _ when imageExts.contains(ext) => FileSystemEntryType.image,
      _ when videoExts.contains(ext) => FileSystemEntryType.video,
      _ when audioExts.contains(ext) => FileSystemEntryType.audio,
      _ when docExts.contains(ext) => FileSystemEntryType.document,
      _ when archiveExts.contains(ext) => FileSystemEntryType.archive,
      _ when appExts.contains(ext) => FileSystemEntryType.app,
      _ => FileSystemEntryType.other,
    };
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
              onLongPress: () => _openInExplorer(context, entry),
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

  void _openInExplorer(BuildContext context, FileSystemEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  entry.path,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.folder_open_rounded),
                  title: const Text('Open in folder'),
                  subtitle: Text(
                    'Browse ${widget.kind.label.toLowerCase()} in full explorer',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () {
                    context.pop();
                    _navigateToExplorer(entry);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToExplorer(FileSystemEntry entry) {
    final folderPath = p.dirname(entry.path);
    final ref = ProviderScope.containerOf(context, listen: false);
    ref.read(explorerFilterTypeProvider.notifier).state = widget.kind.type;
    ref.read(explorerControllerProvider.notifier).openDirectory(folderPath);
    context.go(AppRoutes.explorer);
  }
}

class _MediaGridTile extends StatelessWidget {
  const _MediaGridTile({
    required this.entry,
    required this.onTap,
    this.onLongPress,
  });

  final FileSystemEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final thumbnail = MediaThumbnail(
      entry: entry,
      fallback: fileIconForEntry(context, entry),
      dimension: 120,
    );
    final needsName = entry.type == FileSystemEntryType.document ||
        entry.type == FileSystemEntryType.audio ||
        entry.type == FileSystemEntryType.app ||
        entry.type == FileSystemEntryType.archive;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ClipRect(
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                thumbnail,
                if (needsName)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0),
                            Colors.black.withOpacity(0.75),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                        child: Text(
                          entry.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
