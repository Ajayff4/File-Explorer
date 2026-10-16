import 'dart:io';

import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/entry_actions_button.dart';
import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/domain/entities/remote_entry.dart';
import 'package:file_explorer/features/ftp/presentation/controllers/ftp_browser_controller.dart';
import 'package:file_explorer/features/media/presentation/text_file_viewer_screen.dart';
import 'package:file_explorer/shared/archive/archive_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// Downloads [entry] to temp storage and opens it in the same built-in
/// viewer local files use ([openFileForPreview]).
Future<void> openRemoteFileForPreview({
  required BuildContext context,
  required WidgetRef ref,
  required FtpConnection connection,
  required RemoteEntry entry,
}) async {
  final controller =
      ref.read(ftpBrowserControllerProvider(connection).notifier);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Downloading ${entry.name}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );

  try {
    final bytes = await controller.downloadBytes(entry.path);
    final tempDir = await Directory.systemTemp.createTemp('ftp_preview');
    final file = File(p.join(tempDir.path, entry.name));
    await file.writeAsBytes(bytes, flush: true);

    final localEntry = FileSystemEntry(
      name: entry.name,
      path: file.path,
      type: _typeForName(entry.name),
      modifiedAt: entry.modifiedAt ?? DateTime.now(),
      sizeBytes: bytes.length,
    );
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    openFileForPreview(context: context, ref: ref, entry: localEntry);
  } catch (error) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Download failed: ${controller.downloadErrorMessage(error)}',
        ),
      ),
    );
  }
}

FileSystemEntryType _typeForName(String name) {
  final mimeType = lookupMimeType(name);
  if (mimeType != null) {
    if (mimeType.startsWith('image/')) return FileSystemEntryType.image;
    if (mimeType.startsWith('video/')) return FileSystemEntryType.video;
    if (mimeType.startsWith('audio/')) return FileSystemEntryType.audio;
  }
  if (archiveFormatForPath(name) != null) return FileSystemEntryType.archive;
  if (isTextFile(name)) return FileSystemEntryType.document;
  return FileSystemEntryType.other;
}
