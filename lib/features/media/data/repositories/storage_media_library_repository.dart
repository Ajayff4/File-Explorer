import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/media/data/repositories/media_library_walk_cache.dart';
import 'package:file_explorer/features/media/domain/repositories/media_library_repository.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';

class StorageMediaLibraryRepository implements MediaLibraryRepository {
  const StorageMediaLibraryRepository(
    this._storageRepository, {
    MediaLibraryWalkCache? walkCache,
  }) : _walkCache = walkCache;

  final StorageRepository _storageRepository;
  final MediaLibraryWalkCache? _walkCache;

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
  }) {
    final walkCache = _walkCache;
    if (walkCache != null) {
      return walkCache.resultsFor(rootPath: rootPath, type: type);
    }
    return _walkForType(rootPath: rootPath, type: type);
  }

  Future<List<SearchResult>> _walkForType({
    required String rootPath,
    required FileSystemEntryType type,
  }) async {
    final results = <SearchResult>[];
    await _collectResults(
      path: rootPath,
      type: type,
      results: results,
      visitedPaths: <String>{},
    );
    return results;
  }

  Future<void> _collectResults({
    required String path,
    required FileSystemEntryType type,
    required List<SearchResult> results,
    required Set<String> visitedPaths,
  }) async {
    if (visitedPaths.contains(path)) {
      return;
    }
    visitedPaths.add(path);

    final listing = await _storageRepository.listDirectory(path);

    for (final entry in listing.entries) {
      if (entry.name.startsWith('.')) {
        continue;
      }
      if (entry.type == type) {
        results.add(
          SearchResult(
            entry: entry,
            parentPath: path,
            depth: 0,
          ),
        );
      }
    }

    for (final folder in listing.entries.where((entry) => entry.isFolder)) {
      if (folder.name.startsWith('.')) {
        continue;
      }
      try {
        await _collectResults(
          path: folder.path,
          type: type,
          results: results,
          visitedPaths: visitedPaths,
        );
      } on Object {
        continue;
      }
    }
  }
}
