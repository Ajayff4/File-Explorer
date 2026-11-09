import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/explorer/presentation/entry_filters.dart';
import 'package:file_explorer/features/explorer/presentation/entry_sorting.dart';
import 'package:file_explorer/features/media/data/platform/media_store_platform.dart';
import 'package:file_explorer/features/media/data/platform/media_store_search_results.dart';

/// Returns the entries an Explorer view currently shows: hidden entries
/// removed, the optional type filter applied, and the active sort order.
Future<List<FileSystemEntry>> orderedVisibleExplorerEntries({
  required List<FileSystemEntry> entries,
  required bool showHiddenFiles,
  required ExplorerSortOption sortOption,
  FileSystemEntryType? filterType,
  required StorageRepository storage,
  MediaStorePlatform? mediaStore,
}) async {
  final visible = visibleExplorerEntries(
    entries,
    showHiddenFiles: showHiddenFiles,
  );
  final filtered = filterType == null
      ? visible
      : await filterExplorerEntriesByType(
          entries: visible,
          filterType: filterType,
          storage: storage,
          mediaStore: mediaStore,
        );
  return sortExplorerEntries(filtered, option: sortOption);
}

/// Keeps files of [filterType] and folders that contain at least one entry of
/// that type, annotating folders with the matching count.
Future<List<FileSystemEntry>> filterExplorerEntriesByType({
  required List<FileSystemEntry> entries,
  required FileSystemEntryType filterType,
  required StorageRepository storage,
  MediaStorePlatform? mediaStore,
}) async {
  final filtered = <FileSystemEntry>[];

  for (final entry in entries) {
    if (!entry.isFolder) {
      if (entry.type == filterType) {
        filtered.add(entry);
      }
    } else {
      final matchingCount = await _countMatchingEntries(
        path: entry.path,
        filterType: filterType,
        storage: storage,
        mediaStore: mediaStore,
      );
      if (matchingCount > 0) {
        filtered.add(entry.copyWith(childrenCount: matchingCount));
      }
    }
  }

  return filtered;
}

Future<int> _countMatchingEntries({
  required String path,
  required FileSystemEntryType filterType,
  required StorageRepository storage,
  MediaStorePlatform? mediaStore,
}) async {
  final mediaType =
      mediaStore == null ? null : mediaStoreMediaTypeFor(filterType);
  if (mediaStore != null && mediaType != null) {
    try {
      return await mediaStore.countMedia(mediaType, rootPath: path);
    } on Object {
      // Fall through to the filesystem walk.
    }
  }
  final counts = await storage.countEntriesByType(path);
  return counts[filterType] ?? 0;
}
