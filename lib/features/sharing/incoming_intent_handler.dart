import 'dart:io';

import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/media/presentation/media_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

const _incomingChannel = MethodChannel('com.ajayff4.fileexplorer/incoming');

/// Listens for files opened via "Open with" or shared into the app from other
/// apps (forwarded by the native `MainActivity` over [_incomingChannel) and
/// routes them to the built-in viewers instead of a 3rd-party app.
class IncomingIntentHandler extends ConsumerStatefulWidget {
  const IncomingIntentHandler({
    required this.router,
    required this.child,
    super.key,
  });

  /// The active window's [GoRouter]. Passed in explicitly because this widget
  /// wraps `MaterialApp.router`, so its own `BuildContext` is an *ancestor* of
  /// the router — `GoRouter.of(context)` would therefore find no router.
  final GoRouter router;

  final Widget child;

  @override
  ConsumerState<IncomingIntentHandler> createState() =>
      _IncomingIntentHandlerState();
}

class _IncomingIntentHandlerState extends ConsumerState<IncomingIntentHandler> {
  @override
  void initState() {
    super.initState();
    _incomingChannel.setMethodCallHandler(_handle);
    // Pull any file(s) that arrived before this handler was registered (e.g. a
    // cold-start "Open with" intent queued on the native side). Live intents
    // arriving while the app is already running are pushed via `onFiles`.
    _incomingChannel
        .invokeMethod<List<dynamic>?>('getPending')
        .then((value) {
      final paths = value?.whereType<String>().toList();
      if (paths != null && paths.isNotEmpty) _openPaths(paths);
    });
  }

  @override
  void dispose() {
    _incomingChannel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  Future<dynamic> _handle(MethodCall call) async {
    if (call.method != 'onFiles') return;
    final paths = <String>[];
    if (call.arguments is List) {
      for (final e in call.arguments as List) {
        if (e is String) paths.add(e);
      }
    }
    if (paths.isNotEmpty) _openPaths(paths);
  }

  void _openPaths(List<String> paths) {
    final router = widget.router;
    final scaffoldContext = router.routerDelegate.navigatorKey.currentContext;

    for (final path in paths) {
      final type = _typeForPath(path);
      if (type == FileSystemEntryType.image ||
          type == FileSystemEntryType.video ||
          type == FileSystemEntryType.audio) {
        final entry = _entryFor(path, type);
        router.push(
          AppRoutes.mediaViewer,
          extra: MediaViewerSession(entry: entry, entries: [entry]),
        );
        return;
      }
      if (_isText(path)) {
        router.push(AppRoutes.textViewer, extra: _entryFor(path, FileSystemEntryType.document));
        return;
      }
      if (_isArchive(path)) {
        router.push(AppRoutes.archiveViewer, extra: _entryFor(path, FileSystemEntryType.archive));
        return;
      }
    }

    if (scaffoldContext != null) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text('Received ${paths.length} file(s)')),
      );
    }
  }

  FileSystemEntry _entryFor(String path, FileSystemEntryType type) {
    int? size;
    var modified = DateTime.now();
    try {
      final stat = File(path).statSync();
      size = stat.size;
      modified = stat.modified;
    } catch (_) {
      // Cache copies / unreadable entries still open via the viewers.
    }
    return FileSystemEntry(
      name: p.basename(path),
      path: path,
      type: type,
      modifiedAt: modified,
      sizeBytes: size,
    );
  }

  FileSystemEntryType _typeForPath(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.webp':
      case '.bmp':
      case '.heic':
      case '.heif':
      case '.avif':
        return FileSystemEntryType.image;
      case '.mp4':
      case '.mkv':
      case '.mov':
      case '.webm':
      case '.avi':
      case '.3gp':
      case '.m4v':
      case '.flv':
        return FileSystemEntryType.video;
      case '.mp3':
      case '.wav':
      case '.ogg':
      case '.m4a':
      case '.aac':
      case '.flac':
      case '.opus':
        return FileSystemEntryType.audio;
      default:
        return FileSystemEntryType.other;
    }
  }

  bool _isText(String path) {
    const text = {
      'txt', 'text', 'log', 'md', 'markdown', 'html', 'htm', 'css', 'js', 'json',
      'xml', 'yaml', 'yml', 'toml', 'ini', 'cfg', 'conf', 'sh', 'py', 'dart',
      'java', 'kt', 'c', 'cpp', 'h', 'cs', 'go', 'rs', 'swift', 'sql',
    };
    final ext = p.extension(path).toLowerCase().replaceAll('.', '');
    return text.contains(ext);
  }

  bool _isArchive(String path) {
    const archives = {
      '.zip', '.rar', '.7z', '.tar', '.gz', '.tgz', '.bz2', '.xz', '.zst',
    };
    return archives.contains(p.extension(path).toLowerCase());
  }
}
