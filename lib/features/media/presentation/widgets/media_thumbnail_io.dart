import 'dart:io';

import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

const _apkIconChannel = MethodChannel('com.ajayff4.fileexplorer/apk_icon');

Widget mediaThumbnailFor({
  required FileSystemEntry entry,
  required Widget fallback,
}) {
  return switch (entry.type) {
    FileSystemEntryType.image => Image.file(
        File(entry.path),
        fit: BoxFit.cover,
        cacheWidth: 96,
        errorBuilder: (_, __, ___) => Center(child: fallback),
      ),
    FileSystemEntryType.video => _VideoThumbnail(
        path: entry.path,
        fallback: fallback,
      ),
    FileSystemEntryType.app => _ApkIconThumbnail(
        path: entry.path,
        fallback: fallback,
      ),
    _ => Center(child: fallback),
  };
}

class _ApkIconThumbnail extends StatelessWidget {
  const _ApkIconThumbnail({
    required this.path,
    required this.fallback,
  });

  final String path;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _loadApkIcon(path),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return Center(child: fallback);
        }

        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Center(child: fallback),
        );
      },
    );
  }
}

Future<Uint8List?> _loadApkIcon(String path) async {
  try {
    return await _apkIconChannel.invokeMethod<Uint8List>(
      'getApkIcon',
      {'path': path},
    );
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({
    required this.path,
    required this.fallback,
  });

  final String path;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: VideoThumbnail.thumbnailData(
        video: path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 96,
        quality: 60,
      ),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return Center(child: fallback);
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => Center(child: fallback),
            ),
            const Align(
              alignment: Alignment.center,
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: Color(0xE6FFFFFF),
                size: 24,
              ),
            ),
          ],
        );
      },
    );
  }
}
