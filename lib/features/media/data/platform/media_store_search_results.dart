import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/media/data/platform/media_store_platform.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';
import 'package:path/path.dart' as p;

/// Returns the MediaStore collection for a media [type], or null for types
/// MediaStore does not reliably index (documents, apps, archives, ...).
MediaStoreMediaType? mediaStoreMediaTypeFor(FileSystemEntryType type) {
  return switch (type) {
    FileSystemEntryType.image => MediaStoreMediaType.image,
    FileSystemEntryType.video => MediaStoreMediaType.video,
    FileSystemEntryType.audio => MediaStoreMediaType.audio,
    _ => null,
  };
}

/// Returns the file-system entry type indexed by a MediaStore collection.
FileSystemEntryType fileSystemEntryTypeFor(MediaStoreMediaType type) {
  return switch (type) {
    MediaStoreMediaType.image => FileSystemEntryType.image,
    MediaStoreMediaType.video => FileSystemEntryType.video,
    MediaStoreMediaType.audio => FileSystemEntryType.audio,
  };
}

/// Whether [path] is inside [rootPath] (or is the root itself).
bool isUnderRootPath(String path, String rootPath) {
  if (rootPath.isEmpty) {
    return true;
  }
  return path == rootPath || path.startsWith('$rootPath/');
}

extension MediaStoreMediaItemSearchResult on MediaStoreMediaItem {
  /// Maps a MediaStore row to the flattened-by-parent search-result shape
  /// used by media category views and type-only search.
  SearchResult toSearchResult(FileSystemEntryType type) {
    return SearchResult(
      entry: FileSystemEntry(
        name: name,
        path: path,
        type: type,
        modifiedAt: modifiedAt,
        sizeBytes: sizeBytes,
      ),
      parentPath: p.dirname(path),
      depth: 0,
    );
  }
}
