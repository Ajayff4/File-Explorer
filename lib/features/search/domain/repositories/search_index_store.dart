import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';

abstract interface class SearchIndexStore {
  Future<bool> hasIndex(String rootPath);

  Future<List<SearchResult>> search({
    required String rootPath,
    required String query,
    required Set<FileSystemEntryType> filteredTypes,
    required int maxResults,
  });

  Future<void> replaceIndex({
    required String rootPath,
    required List<SearchResult> entries,
  });

  Future<void> clearIndex(String rootPath);

  Future<void> clearIndexesForPaths(List<String> paths);
}
