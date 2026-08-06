import 'dart:io';

import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

const _apkIconChannel = MethodChannel('com.ajayff4.fileexplorer/apk_icon');

final _thumbnailCache = <String, Uint8List?>{};
final _thumbnailFutures = <String, Future<Uint8List?>>{};

String _getCachePath(String videoPath, int maxWidth) {
  final hash = videoPath.hashCode ^ maxWidth.hashCode;
  final dir = '${Directory.systemTemp.path}/video_thumbnails';
  return '$dir/$hash.jpg';
}

Future<void> _ensureCacheDir() async {
  final dir = Directory('${Directory.systemTemp.path}/video_thumbnails');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}

Future<Uint8List?> _getVideoThumbnail(String path, int maxWidth) {
  final cacheKey = '$path:$maxWidth';
  if (_thumbnailCache.containsKey(cacheKey)) {
    return Future.value(_thumbnailCache[cacheKey]);
  }
  if (_thumbnailFutures.containsKey(cacheKey)) {
    return _thumbnailFutures[cacheKey]!;
  }

  final future = () async {
    try {
      await _ensureCacheDir();
      final cachePath = _getCachePath(path, maxWidth);
      final cacheFile = File(cachePath);
      if (await cacheFile.exists()) {
        final bytes = await cacheFile.readAsBytes();
        _thumbnailCache[cacheKey] = bytes;
        return bytes;
      }

      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: path,
        thumbnailPath: Directory.systemTemp.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: maxWidth,
        quality: 70,
      );

      if (thumbnailPath != null) {
        final file = File(thumbnailPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          _thumbnailCache[cacheKey] = bytes;
          try {
            final cacheFile = File(cachePath);
            await cacheFile.writeAsBytes(bytes);
            await file.delete();
          } catch (_) {}
          return bytes;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }();

  _thumbnailFutures[cacheKey] = future;
  future.whenComplete(() => _thumbnailFutures.remove(cacheKey));
  return future;
}

Widget mediaThumbnailFor({
  required FileSystemEntry entry,
  required Widget fallback,
  double dimension = 48,
}) {
  return switch (entry.type) {
    FileSystemEntryType.image => Image.file(
        File(entry.path),
        fit: BoxFit.cover,
        cacheWidth: (dimension * 2).round(),
        errorBuilder: (_, __, ___) => Center(child: fallback),
      ),
    FileSystemEntryType.video => _VideoThumbnail(
        path: entry.path,
        fallback: fallback,
        maxWidth: (dimension * 2).round(),
      ),
    FileSystemEntryType.app => _ApkIconThumbnail(
        path: entry.path,
        fallback: fallback,
      ),
    _ => Center(child: fallback),
  };
}

class _ApkIconThumbnail extends StatefulWidget {
  const _ApkIconThumbnail({
    required this.path,
    required this.fallback,
  });

  final String path;
  final Widget fallback;

  @override
  State<_ApkIconThumbnail> createState() => _ApkIconThumbnailState();
}

class _ApkIconThumbnailState extends State<_ApkIconThumbnail> {
  Uint8List? _bytes;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  Future<void> _loadIcon() async {
    try {
      final bytes = await _apkIconChannel.invokeMethod<Uint8List>(
        'getApkIcon',
        {'path': widget.path},
      );
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _loaded = true;
        });
      }
    } on PlatformException {
      if (mounted) setState(() => _loaded = true);
    } on MissingPluginException {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Center(child: widget.fallback);
    }
    if (_bytes == null) {
      return Center(child: widget.fallback);
    }
    return Image.memory(
      _bytes!,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Center(child: widget.fallback),
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  const _VideoThumbnail({
    required this.path,
    required this.fallback,
    this.maxWidth = 256,
  });

  final String path;
  final Widget fallback;
  final int maxWidth;

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  Uint8List? _bytes;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant _VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.maxWidth != widget.maxWidth) {
      _loaded = false;
      _bytes = null;
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    final bytes = await _getVideoThumbnail(widget.path, widget.maxWidth);
    if (mounted) {
      setState(() {
        _bytes = bytes;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Center(child: widget.fallback);
    }
    if (_bytes == null) {
      return Center(child: widget.fallback);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          _bytes!,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Center(child: widget.fallback),
        ),
        const Align(
          alignment: Alignment.center,
          child: Icon(
            Icons.play_circle_fill_rounded,
            color: Color(0xE6FFFFFF),
            size: 32,
          ),
        ),
      ],
    );
  }
}
