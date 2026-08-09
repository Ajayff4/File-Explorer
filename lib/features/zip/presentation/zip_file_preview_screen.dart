import 'dart:convert';
import 'dart:io';

import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/media/presentation/local_media_actions.dart';
import 'package:file_explorer/features/media/presentation/text_file_viewer_screen.dart';
import 'package:file_explorer/features/zip/domain/entities/zip_entry.dart';
import 'package:file_explorer/features/zip/presentation/controllers/zip_viewer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum ZipPreviewKind { image, video, audio, text, unsupported }

class ZipFilePreviewSession {
  const ZipFilePreviewSession({
    required this.archivePath,
    required this.entry,
  });

  final String archivePath;
  final ZipEntry entry;
}

class ZipFilePreviewScreen extends ConsumerStatefulWidget {
  const ZipFilePreviewScreen({
    required this.archivePath,
    required this.entry,
    super.key,
  });

  final String archivePath;
  final ZipEntry entry;

  @override
  ConsumerState<ZipFilePreviewScreen> createState() =>
      _ZipFilePreviewScreenState();
}

class _ZipFilePreviewScreenState extends ConsumerState<ZipFilePreviewScreen> {
  late final ZipPreviewKind _kind;
  Uint8List? _bytes;
  Object? _error;
  bool _loading = true;

  File? _tempFile;

  ZipEntry get _entry => widget.entry;

  @override
  void initState() {
    super.initState();
    _kind = kindForZipPreview(_entry.name);
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
          .read(zipViewerControllerProvider(widget.archivePath).notifier)
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

  bool _isMedia(ZipPreviewKind kind) {
    return kind == ZipPreviewKind.image ||
        kind == ZipPreviewKind.video ||
        kind == ZipPreviewKind.audio;
  }

  FileSystemEntryType _typeForKind(ZipPreviewKind kind) {
    return switch (kind) {
      ZipPreviewKind.image => FileSystemEntryType.image,
      ZipPreviewKind.video => FileSystemEntryType.video,
      ZipPreviewKind.audio => FileSystemEntryType.audio,
      _ => FileSystemEntryType.other,
    };
  }

  Future<File> _writeTempMediaFile(Uint8List bytes) async {
    final extension = _extensionFor(_entry.name);
    final tempFile = File(
      '${Directory.systemTemp.path}/zip_media_'
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
      '${Directory.systemTemp.path}/zip_open_'
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
          _kind == ZipPreviewKind.image || _kind == ZipPreviewKind.video
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
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ZipPreviewError(error: _error!);
    }

    final bytes = _bytes ?? Uint8List(0);

    return switch (_kind) {
      ZipPreviewKind.image ||
      ZipPreviewKind.video ||
      ZipPreviewKind.audio =>
        const Center(child: CircularProgressIndicator()),
      ZipPreviewKind.text => _ZipTextPreview(
          text: utf8.decode(bytes, allowMalformed: true),
        ),
      ZipPreviewKind.unsupported => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility_off_rounded,
                  size: 48, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Preview not available for this file type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
    };
  }
}

class _ZipTextPreview extends StatelessWidget {
  const _ZipTextPreview({required this.text});

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

class _ZipPreviewError extends StatelessWidget {
  const _ZipPreviewError({required this.error});

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

ZipPreviewKind kindForZipPreview(String name) {
  final extension = _extensionFor(name);
  return switch (extension) {
    'jpg' ||
    'jpeg' ||
    'png' ||
    'gif' ||
    'webp' ||
    'heic' ||
    'bmp' =>
      ZipPreviewKind.image,
    'mp4' || 'mkv' || 'mov' || 'webm' || 'avi' => ZipPreviewKind.video,
    'mp3' || 'flac' || 'wav' || 'm4a' || 'ogg' || 'aac' => ZipPreviewKind.audio,
    _ => isTextFile(name) ? ZipPreviewKind.text : ZipPreviewKind.unsupported,
  };
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
