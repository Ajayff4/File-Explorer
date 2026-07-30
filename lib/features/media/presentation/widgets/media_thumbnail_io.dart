import 'dart:io';
import 'dart:typed_data';

import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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
    _ => Center(child: fallback),
  };
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
