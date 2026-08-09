import 'dart:async';

import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/search/presentation/controllers/file_search_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pre-builds the persisted search index for the storage root(s) once
/// storage access is confirmed, so folder searches resolve without an
/// on-demand walk.
///
/// Folders are not indexed by MediaStore, so the index must be built by
/// walking the filesystem once; doing so silently in the background means the
/// first folder search is already fast.
final searchIndexPreWarmProvider = Provider<void>((ref) {
  ref.listen<ExplorerState>(explorerControllerProvider, (previous, next) {
    final permission = next.permission.value;
    if (permission == null || !permission.canBrowse) {
      return;
    }

    final roots = <String>{
      for (final volume in next.volumes.value ?? const <StorageVolume>[])
        volume.path,
      if (next.currentPath.isNotEmpty) next.currentPath,
    };
    if (roots.isEmpty) {
      return;
    }

    for (final root in roots) {
      unawaited(_warmUpSafely(ref, root));
    }
  });
});

Future<void> _warmUpSafely(Ref ref, String root) async {
  try {
    await ref.read(fileSearchControllerProvider.notifier).warmUpIndex(root);
  } on Object {
    // Best-effort background warm-up; failures must not surface.
  }
}
