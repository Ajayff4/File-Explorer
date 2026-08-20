import 'dart:convert';
import 'dart:io';

import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/media/presentation/local_media_actions.dart';
import 'package:file_explorer/features/media/presentation/text_file_viewer_screen.dart';
import 'package:file_explorer/features/archive/domain/entities/archive_entry.dart';
import 'package:file_explorer/features/archive/presentation/controllers/archive_viewer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum ArchivePreviewKind { image, video, audio, text, unsupported }

class ArchiveFilePreviewSession {
  const ArchiveFilePreviewSession({
    required this.archivePath,
    required this.entry,
  });

  final String archivePath;
  final ArchiveEntry entry;
}

class ArchiveFilePreviewScreen extends ConsumerStatefulWidget {
  const ArchiveFilePreviewScreen({
    required this.archivePath,
    required this.entry,
    super.key,
  });

  final String archivePath;
  final ArchiveEntry entry;

  @override
  ConsumerState<ArchiveFilePreviewScreen> createState() =>
      _ArchiveFilePreviewScreenState();
}

class _ArchiveFilePreviewScreenState
    extends ConsumerState<ArchiveFilePreviewScreen> {
  late final ArchivePreviewKind _kind;
  Uint8List? _bytes;
  Object? _error;
  bool _loading = true;

  File? _tempFile;

  ArchiveEntry get _entry => widget.entry;

  @override
  void initState() {
    super.initState();
    _kind = kindForArchivePreview(_entry.name);
    _loadEntry();
  }

  @override
  void dispose() {
    if (_tempFile != null) {
      try {
        _tempFile!.deleteSync();
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _loadEntry() async {
    try {
      final bytes = await ref
          .read(archiveViewerControllerProvider(widget.archivePath).notifier)
          .readEntry(_entry.path);
      if (!mounted) {
        return;
      }
      if (bytes == null) {
        setState(() {
          _error = 'Could not read entry from archive';
          _loading = false;
        });
        return;
      }
      if (_isMedia(_kind)) {
        await _openMediaInSharedViewer(bytes);
        return;
      }
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  bool _isMedia(ArchivePreviewKind kind) {
    return kind == ArchivePreviewKind.image ||
        kind == ArchivePreviewKind.video ||
        kind == ArchivePreviewKind.audio;
  }

  FileSystemEntryType _typeForKind(ArchivePreviewKind kind) {
    return switch (kind) {
      ArchivePreviewKind.image => FileSystemEntryType.image,
      ArchivePreviewKind.video => FileSystemEntryType.video,
      ArchivePreviewKind.audio => FileSystemEntryType.audio,
      _ => FileSystemEntryType.other,
    };
  }

  Future<File> _writeTempMediaFile(Uint8List bytes) async {
    final extension = _extensionFor(_entry.name);
    final tempFile = File(
      '${Directory.systemTemp.path}/archive_media_'
      '${DateTime.now().microsecondsSinceEpoch}.$extension',
    );
    await tempFile.writeAsBytes(bytes);
    _tempFile = tempFile;
    return tempFile;
  }

  Future<void> _openMediaInSharedViewer(Uint8List bytes) async {
    try {
      final file = await _writeTempMediaFile(bytes);
      if (!mounted) {
        return;
      }
      await context.push(
        AppRoutes.mediaViewer,
        extra: FileSystemEntry(
          name: _entry.name,
          path: file.path,
          type: _typeForKind(_kind),
          modifiedAt: DateTime.now(),
          sizeBytes: bytes.length,
        ),
      );
      if (mounted) {
        Navigator.of(context).maybePop();
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

  Future<File> _ensureTempFile() async {
    final existing = _tempFile;
    if (existing != null) {
      return existing;
    }
    final extension = _extensionFor(_entry.name);
    final tempFile = File(
      '${Directory.systemTemp.path}/archive_open_'
      '${DateTime.now().microsecondsSinceEpoch}.$extension',
    );
    await tempFile.writeAsBytes(_bytes ?? Uint8List(0));
    _tempFile = tempFile;
    return tempFile;
  }

  Future<void> _openWithSystem() async {
    try {
      final file = await _ensureTempFile();
      if (!mounted) {
        return;
      }
      await openLocalFileWithSystem(file.path);
    } on MissingPluginException {
      _showMessage('Open with is available on Android');
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'Could not open file');
    }
  }

  Future<void> _openAsSystem(String mimeType) async {
    try {
      final file = await _ensureTempFile();
      if (!mounted) {
        return;
      }
      await openLocalFileWithSystem(file.path, fallbackMimeType: mimeType);
    } on MissingPluginException {
      _showMessage('Open with is available on Android');
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'Could not open file');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showOpenAsSheet() {
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
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.category_rounded),
                title: Text(
                  _entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: const Text('Open as'),
              ),
              const Divider(),
              for (final option in _OpenAsOption.values)
                ListTile(
                  leading: Icon(option.icon),
                  title: Text(option.label),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openAsSystem(option.mimeType);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _kind == ArchivePreviewKind.image || _kind == ArchivePreviewKind.video
              ? Colors.black
              : null,
      appBar: AppBar(
        title: Text(
          _entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Open with',
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: _openWithSystem,
          ),
          IconButton(
            tooltip: 'Open as',
            icon: const Icon(Icons.category_rounded),
            onPressed: _showOpenAsSheet,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ArchivePreviewError(error: _error!);
    }

    final bytes = _bytes ?? Uint8List(0);

    return switch (_kind) {
      ArchivePreviewKind.image ||
      ArchivePreviewKind.video ||
      ArchivePreviewKind.audio =>
        const Center(child: CircularProgressIndicator()),
      ArchivePreviewKind.text => _ArchiveTextPreview(
          text: utf8.decode(bytes, allowMalformed: true),
        ),
      ArchivePreviewKind.unsupported => const SizedBox.shrink(),
    };
  }
}

class _ArchiveTextPreview extends StatelessWidget {
  const _ArchiveTextPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          text,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ArchivePreviewError extends StatelessWidget {
  const _ArchivePreviewError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Could not preview file',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

ArchivePreviewKind kindForArchivePreview(String name) {
  final extension = _extensionFor(name);
  return switch (extension) {
    'jpg' ||
    'jpeg' ||
    'png' ||
    'gif' ||
    'webp' ||
    'heic' ||
    'bmp' =>
      ArchivePreviewKind.image,
    'mp4' || 'mkv' || 'mov' || 'webm' || 'avi' => ArchivePreviewKind.video,
    'mp3' ||
    'flac' ||
    'wav' ||
    'm4a' ||
    'ogg' ||
    'aac' =>
      ArchivePreviewKind.audio,
    _ => isTextFile(name)
        ? ArchivePreviewKind.text
        : ArchivePreviewKind.unsupported,
  };
}

/// Bottom sheet offered when an entry inside an archive cannot be previewed by
/// any built-in viewer, replacing the dedicated "Preview unavailable" screen.
void showUnsupportedArchiveEntrySheet({
  required BuildContext context,
  required WidgetRef ref,
  required String archivePath,
  required ArchiveEntry entry,
}) {
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
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.visibility_off_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              title: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: const Text('Preview not available'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Open with'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openArchiveEntryWithSystem(
                  context: context,
                  ref: ref,
                  archivePath: archivePath,
                  entry: entry,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.category_rounded),
              title: const Text('Open as'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showArchiveOpenAsSheet(
                  context: context,
                  ref: ref,
                  archivePath: archivePath,
                  entry: entry,
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<File> _writeArchiveEntryToTempFile({
  required WidgetRef ref,
  required String archivePath,
  required ArchiveEntry entry,
}) async {
  final bytes = await ref
      .read(archiveViewerControllerProvider(archivePath).notifier)
      .readEntry(entry.path);
  if (bytes == null) {
    throw Exception('Could not read entry from archive');
  }
  final extension = _extensionFor(entry.name);
  final tempFile = File(
    '${Directory.systemTemp.path}/archive_open_'
    '${DateTime.now().microsecondsSinceEpoch}.$extension',
  );
  await tempFile.writeAsBytes(bytes);
  return tempFile;
}

Future<void> _openArchiveEntryWithSystem({
  required BuildContext context,
  required WidgetRef ref,
  required String archivePath,
  required ArchiveEntry entry,
}) async {
  try {
    final file = await _writeArchiveEntryToTempFile(
      ref: ref,
      archivePath: archivePath,
      entry: entry,
    );
    if (!context.mounted) {
      return;
    }
    await openLocalFileWithSystem(file.path);
  } on MissingPluginException {
    if (!context.mounted) {
      return;
    }
    _showArchiveMessage(context, 'Open with is available on Android');
  } on PlatformException catch (error) {
    if (!context.mounted) {
      return;
    }
    _showArchiveMessage(context, error.message ?? 'Could not open file');
  }
}

void _showArchiveMessage(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

void _showArchiveOpenAsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String archivePath,
  required ArchiveEntry entry,
}) {
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
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.category_rounded),
              title: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: const Text('Open as'),
            ),
            const Divider(),
            for (final option in _OpenAsOption.values)
              ListTile(
                leading: Icon(option.icon),
                title: Text(option.label),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openArchiveEntryAs(
                    context: context,
                    ref: ref,
                    archivePath: archivePath,
                    entry: entry,
                    mimeType: option.mimeType,
                  );
                },
              ),
          ],
        ),
      );
    },
  );
}

Future<void> _openArchiveEntryAs({
  required BuildContext context,
  required WidgetRef ref,
  required String archivePath,
  required ArchiveEntry entry,
  required String mimeType,
}) async {
  try {
    final file = await _writeArchiveEntryToTempFile(
      ref: ref,
      archivePath: archivePath,
      entry: entry,
    );
    if (!context.mounted) {
      return;
    }
    await openLocalFileWithSystem(file.path, fallbackMimeType: mimeType);
  } on MissingPluginException {
    if (!context.mounted) {
      return;
    }
    _showArchiveMessage(context, 'Open with is available on Android');
  } on PlatformException catch (error) {
    if (!context.mounted) {
      return;
    }
    _showArchiveMessage(context, error.message ?? 'Could not open file');
  }
}

enum _OpenAsOption {
  text('Text', Icons.article_rounded, 'text/plain'),
  image('Image', Icons.image_rounded, 'image/*'),
  video('Video', Icons.movie_rounded, 'video/*'),
  audio('Audio', Icons.music_note_rounded, 'audio/*');

  const _OpenAsOption(this.label, this.icon, this.mimeType);
  final String label;
  final IconData icon;
  final String mimeType;
}

String _extensionFor(String name) {
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == name.length - 1) {
    return '';
  }
  return name.substring(dotIndex + 1).toLowerCase();
}
