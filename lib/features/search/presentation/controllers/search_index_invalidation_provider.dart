import 'dart:async';

import 'package:file_explorer/features/search/data/repositories/search_index_store_provider.dart';
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

    unawaited(
      ref.read(searchIndexStoreProvider).clearIndexesForPaths(touchedPaths),
    );
  });
});
