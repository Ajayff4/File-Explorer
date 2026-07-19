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

  @override
  Future<void> clearIndexesForPaths(List<String> paths) async {
    if (paths.isEmpty) {
      return;
    }
    _entriesByRoot.removeWhere(
      (rootPath, entries) => paths.any((path) => _pathsOverlap(rootPath, path)),
    );
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

  bool _pathsOverlap(String left, String right) {
    if (left == right) {
      return true;
    }
    return _isChildPath(left, right) || _isChildPath(right, left);
  }

  bool _isChildPath(String parent, String child) {
    if (parent == '/') {
      return child.startsWith('/');
    }
    return child.startsWith('$parent/');
  }
}
