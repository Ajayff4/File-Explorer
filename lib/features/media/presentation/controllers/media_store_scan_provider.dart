import 'dart:async';

import 'package:file_explorer/features/media/data/platform/media_store_platform.dart';
import 'package:file_explorer/features/media/data/repositories/media_library_repository_provider.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps Android's MediaStore index in sync with completed transfers.
///
/// Newly created files (copy/move/rename/extract/compress destinations) are
/// sent to the OS media scanner so they appear in MediaStore-backed views
/// immediately; source paths of moved/deleted files are scanned too, which
/// prunes their stale rows.
final mediaStoreScanProvider = Provider<void>((ref) {
  ref.listen<TransferState>(transferControllerProvider, (previous, next) {
    final mediaStore = ref.read(mediaStorePlatformProvider);
    if (mediaStore == null) {
      return;
    }

    final previousStatuses = {
      for (final task in previous?.tasks ?? const <TransferTask>[])
        task.id: task.status,
    };

    final pathsToScan = <String>{};
    for (final task in next.tasks) {
      final didComplete = task.status == TransferTaskStatus.completed &&
          previousStatuses[task.id] != TransferTaskStatus.completed;
      if (!didComplete) {
        continue;
      }
      pathsToScan.addAll(task.sourcePaths);
      final destinationPath = task.destinationPath;
      if (destinationPath != null && destinationPath.isNotEmpty) {
        pathsToScan.add(destinationPath);
      }
    }

    if (pathsToScan.isEmpty) {
      return;
    }

    unawaited(
      _scanSafely(
        mediaStore,
        pathsToScan.toList(growable: false),
      ),
    );
  });
});

Future<void> _scanSafely(
    MediaStorePlatform platform, List<String> paths) async {
  try {
    await platform.scanFiles(paths);
  } on Object {
    // Scanning is best-effort; failures must not surface as unhandled errors.
  }
}
