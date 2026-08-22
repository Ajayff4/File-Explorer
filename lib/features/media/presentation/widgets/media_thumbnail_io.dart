import 'dart:io';

import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/media/data/thumbnail_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _apkIconChannel = MethodChannel('com.ajayff4.fileexplorer/apk_icon');

Widget mediaThumbnailFor({
  required FileSystemEntry entry,
  required Widget fallback,
  double dimension = 48,
}) {
  final maxWidth = (dimension * 2).round();
  return switch (entry.type) {
    FileSystemEntryType.image => _ImageThumbnail(
        path: entry.path,
        fallback: fallback,
        maxWidth: maxWidth,
      ),
    FileSystemEntryType.video => _VideoThumbnail(
        path: entry.path,
        fallback: fallback,
        maxWidth: maxWidth,
      ),
    FileSystemEntryType.app => _ApkIconThumbnail(
        path: entry.path,
        fallback: fallback,
      ),
    _ => Center(child: fallback),
  };
}

class _ImageThumbnail extends StatefulWidget {
  const _ImageThumbnail({
    required this.path,
    required this.fallback,
    required this.maxWidth,
  });

  final String path;
  final Widget fallback;
  final int maxWidth;

  @override
  State<_ImageThumbnail> createState() => _ImageThumbnailState();
}

class _ImageThumbnailState extends State<_ImageThumbnail> {
  Uint8List? _bytes;
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _ImageThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path || oldWidget.maxWidth != widget.maxWidth) {
      _bytes = null;
      _settled = false;
      _load();
    }
  }

  Future<void> _load() async {
    final bytes = await nativeThumbnail(widget.path, widget.maxWidth);
    if (mounted) {
      setState(() {
        _bytes = bytes;
        _settled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Center(child: widget.fallback),
      );
    }
    if (_settled) {
      return Image.file(
        File(widget.path),
        fit: BoxFit.cover,
        cacheWidth: widget.maxWidth,
        errorBuilder: (_, __, ___) => Center(child: widget.fallback),
      );
    }
    return Center(child: widget.fallback);
  }
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
    var bytes = await nativeThumbnail(widget.path, widget.maxWidth);
    bytes ??= await decodedVideoThumbnail(widget.path, widget.maxWidth);
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
