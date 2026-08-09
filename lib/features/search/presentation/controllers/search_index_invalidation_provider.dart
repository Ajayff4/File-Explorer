import 'dart:async';

import 'package:file_explorer/features/search/data/repositories/search_index_store_provider.dart';
import 'package:file_explorer/features/search/presentation/controllers/file_search_controller.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchIndexInvalidationProvider = Provider<void>((ref) {
  ref.listen<TransferState>(transferControllerProvider, (previous, next) {
    final previousStatuses = {
      for (final task in previous?.tasks ?? const <TransferTask>[])
        task.id: task.status,
    };

    final touchedPaths = <String>[];
    for (final task in next.tasks) {
      final previousStatus = previousStatuses[task.id];
      final didComplete = task.status == TransferTaskStatus.completed &&
          previousStatus != TransferTaskStatus.completed;
      if (!didComplete) {
        continue;
      }
      touchedPaths.addAll(task.sourcePaths);
      final destinationPath = task.destinationPath;
      if (destinationPath != null && destinationPath.isNotEmpty) {
        touchedPaths.add(destinationPath);
      }
    }

    if (touchedPaths.isEmpty) {
      return;
    }

    unawaited(_reInitAndWarm(ref, touchedPaths));
  });
});

/// Clears any index overlapping [touchedPaths] and immediately re-warms the
/// cleared roots, so the index the transfer invalidated is rebuilt in the
/// background rather than left missing (which would force the next folder
/// search to walk the tree again).
Future<void> _reInitAndWarm(Ref ref, List<String> touchedPaths) async {
  try {
    final clearedRoots = await ref
        .read(searchIndexStoreProvider)
        .clearIndexesForPaths(touchedPaths);
    for (final root in clearedRoots) {
      unawaited(ref.read(fileSearchControllerProvider.notifier).warmUpIndex(root));
    }
  } on Object {
    // Invalidation is best-effort; failures must not surface.
  }
}
