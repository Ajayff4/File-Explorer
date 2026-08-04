import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/media/domain/repositories/media_library_repository.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';

class StorageMediaLibraryRepository implements MediaLibraryRepository {
  const StorageMediaLibraryRepository(this._storageRepository);

  final StorageRepository _storageRepository;

  @override
  Future<List<SearchResult>> findByType({
    required String rootPath,
    required FileSystemEntryType type,
    int maxDepth = 64,
  }) async {
    final results = <SearchResult>[];
    await _collectResults(
      path: rootPath,
      type: type,
      results: results,
      visitedPaths: <String>{},
      depth: 0,
      maxDepth: maxDepth,
    );
    return results;
  }

  @override
  Future<List<SearchResult>> findFoldersWithMedia({
    required String rootPath,
    required FileSystemEntryType type,
  }) async {
    final results = <SearchResult>[];
    await _collectResults(
      path: rootPath,
      type: type,
      results: results,
      visitedPaths: <String>{},
      depth: 0,
      maxDepth: 64,
    );
    return results;
  }

  Future<void> _collectResults({
    required String path,
    required FileSystemEntryType type,
    required List<SearchResult> results,
    required Set<String> visitedPaths,
    required int depth,
    required int maxDepth,
  }) async {
    if (depth > maxDepth || visitedPaths.contains(path)) {
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
            depth: depth,
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
          depth: depth + 1,
          maxDepth: maxDepth,
        );
      } on Object {
        continue;
      }
    }
  }
}
