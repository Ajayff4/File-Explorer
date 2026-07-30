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
    int maxResults = 50000,
  }) async {
    final results = <SearchResult>[];
    await _collectResults(
      path: rootPath,
      type: type,
      results: results,
      visitedPaths: <String>{},
      depth: 0,
      maxDepth: maxDepth,
      maxResults: maxResults,
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
    required int maxResults,
  }) async {
    if (depth > maxDepth ||
        visitedPaths.contains(path) ||
        results.length >= maxResults) {
      return;
    }
    visitedPaths.add(path);

    final listing = await _storageRepository.listDirectory(path);

    for (final entry in listing.entries) {
      if (results.length >= maxResults) {
        break;
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
      if (results.length >= maxResults) {
        break;
      }
      try {
        await _collectResults(
          path: folder.path,
          type: type,
          results: results,
          visitedPaths: visitedPaths,
          depth: depth + 1,
          maxDepth: maxDepth,
          maxResults: maxResults,
        );
      } on Object {
        continue;
      }
    }
  }
}
