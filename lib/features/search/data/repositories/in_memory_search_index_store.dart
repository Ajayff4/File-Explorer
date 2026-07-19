import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';
import 'package:file_explorer/features/search/domain/repositories/search_index_store.dart';

class InMemorySearchIndexStore implements SearchIndexStore {
  final Map<String, List<SearchResult>> _entriesByRoot = {};

  @override
  Future<bool> hasIndex(String rootPath) async {
    return _entriesByRoot.containsKey(rootPath);
  }

  @override
  Future<List<SearchResult>> search({
    required String rootPath,
    required String query,
    required Set<FileSystemEntryType> filteredTypes,
    required int maxResults,
  }) async {
    final normalizedQuery = query.toLowerCase();
    return (_entriesByRoot[rootPath] ?? const <SearchResult>[])
        .where(
          (result) => _matches(result.entry, normalizedQuery, filteredTypes),
        )
        .take(maxResults)
        .toList(growable: false);
  }

  @override
  Future<void> replaceIndex({
    required String rootPath,
    required List<SearchResult> entries,
  }) async {
    _entriesByRoot[rootPath] = List.unmodifiable(entries);
  }

  @override
  Future<void> clearIndex(String rootPath) async {
    _entriesByRoot.remove(rootPath);
  }

  bool _matches(
    FileSystemEntry entry,
    String query,
    Set<FileSystemEntryType> filteredTypes,
  ) {
    if (filteredTypes.isNotEmpty && !filteredTypes.contains(entry.type)) {
      return false;
    }
    return entry.name.toLowerCase().contains(query) ||
        entry.path.toLowerCase().contains(query);
  }
}
