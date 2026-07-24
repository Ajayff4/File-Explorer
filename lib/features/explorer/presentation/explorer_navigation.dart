import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

String normalizeExplorerPath(String path) {
  if (path.isEmpty || path == '/') {
    return path;
  }
  return p.normalize(path);
}

StorageVolume? volumeForExplorerPath(
  String currentPath,
  List<StorageVolume> volumes, {
  StorageVolume? listingVolume,
}) {
  if (listingVolume != null) {
    return listingVolume;
  }

  final normalizedPath = normalizeExplorerPath(currentPath);
  StorageVolume? bestMatch;
  for (final volume in volumes) {
    final volumePath = normalizeExplorerPath(volume.path);
    if (_isSameOrUnderPath(normalizedPath, volumePath) &&
        (bestMatch == null ||
            volumePath.length >
                normalizeExplorerPath(bestMatch.path).length)) {
      bestMatch = volume;
    }
  }
  return bestMatch ?? (volumes.isEmpty ? null : volumes.first);
}

bool canNavigateUpInExplorer(ExplorerState state) {
  final normalizedCurrent = normalizeExplorerPath(state.currentPath);
  final volume = volumeForExplorerPath(
    normalizedCurrent,
    state.volumes.valueOrNull ?? const <StorageVolume>[],
    listingVolume: state.listing.valueOrNull?.volume,
  );
  final volumeRoot = volume?.path;
  if (volumeRoot != null) {
    return normalizedCurrent != normalizeExplorerPath(volumeRoot);
  }
  return normalizedCurrent !=
      normalizeExplorerPath(p.dirname(normalizedCurrent));
}

bool _isSameOrUnderPath(String path, String root) {
  if (path == root) {
    return true;
  }
  return path.startsWith('$root${p.separator}');
}
