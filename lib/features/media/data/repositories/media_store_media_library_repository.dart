import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/media/data/platform/media_store_platform.dart';
import 'package:file_explorer/features/media/domain/repositories/media_library_repository.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';
import 'package:path/path.dart' as p;

/// Media-library repository backed by Android's MediaStore index.
///
/// MediaStore is maintained by the OS media scanner, so querying it avoids
/// a recursive filesystem walk and returns the complete index for a media
/// type regardless of folder depth. Non-media types and any query failure
/// delegate to [fallback] (the recursive walker).
class MediaStoreMediaLibraryRepository implements MediaLibraryRepository {
  const MediaStoreMediaLibraryRepository({
    required MediaStorePlatform platform,
    required MediaLibraryRepository fallback,
  })  : _platform = platform,
        _fallback = fallback;

  final MediaStorePlatform _platform;
  final MediaLibraryRepository _fallback;

  @override
  Future<List<SearchResult>> findByType({
    required String rootPath,
    required FileSystemEntryType type,
  }) {
    return _find(rootPath: rootPath, type: type);
  }

  @override
  Future<List<SearchResult>> findFoldersWithMedia({
    required String rootPath,
    required FileSystemEntryType type,
  }) {
    return _find(rootPath: rootPath, type: type);
  }

  Future<List<SearchResult>> _find({
    required String rootPath,
    required FileSystemEntryType type,
  }) async {
    final mediaType = _mediaTypeFor(type);
    if (mediaType == null) {
      return _fallback.findByType(rootPath: rootPath, type: type);
    }

    try {
      final items = await _platform.queryMedia(mediaType);
      return [
        for (final item in items)
          if (_isUnderRoot(item.path, rootPath))
            SearchResult(
              entry: FileSystemEntry(
                name: item.name,
                path: item.path,
                type: type,
                modifiedAt: item.modifiedAt,
                sizeBytes: item.sizeBytes,
              ),
              parentPath: p.dirname(item.path),
              depth: 0,
            ),
      ];
    } on Object {
      return _fallback.findByType(rootPath: rootPath, type: type);
    }
  }

  static MediaStoreMediaType? _mediaTypeFor(FileSystemEntryType type) {
    return switch (type) {
      FileSystemEntryType.image => MediaStoreMediaType.image,
      FileSystemEntryType.video => MediaStoreMediaType.video,
      FileSystemEntryType.audio => MediaStoreMediaType.audio,
      _ => null,
    };
  }

  static bool _isUnderRoot(String path, String rootPath) {
    if (rootPath.isEmpty) {
      return true;
    }
    return path == rootPath || path.startsWith('$rootPath/');
  }
}
