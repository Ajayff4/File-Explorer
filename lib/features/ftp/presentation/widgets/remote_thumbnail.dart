import 'dart:typed_data';

import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/domain/entities/remote_entry.dart';
import 'package:file_explorer/features/ftp/presentation/controllers/ftp_browser_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Server-image thumbnail with icon fallback. Fetch, downscale, and cache
/// live in the browser controller; this only renders.
class RemoteThumbnail extends ConsumerWidget {
  const RemoteThumbnail({
    required this.connection,
    required this.entry,
    required this.size,
    required this.fallback,
    super.key,
  });

  final FtpConnection connection;
  final RemoteEntry entry;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entry.isDirectory ||
        !FtpBrowserController.isImageName(entry.name)) {
      return fallback;
    }
    final future = ref
        .read(ftpBrowserControllerProvider(connection).notifier)
        .thumbnailFor(entry);
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return fallback;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        );
      },
    );
  }
}
