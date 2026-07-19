import 'package:drift/drift.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';
import 'package:file_explorer/features/search/domain/repositories/search_index_store.dart';
import 'package:file_explorer/shared/database/app_database.dart';

class DriftSearchIndexStore implements SearchIndexStore {
  const DriftSearchIndexStore(this._database);

  final AppDatabase _database;

  @override
  Future<bool> hasIndex(String rootPath) async {
    final row = await (_database.select(_database.searchIndexEntryRows)
          ..where((table) => table.rootPath.equals(rootPath))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  @override
  Future<List<SearchResult>> search({
    required String rootPath,
    required String query,
    required Set<FileSystemEntryType> filteredTypes,
    required int maxResults,
  }) async {
    final normalizedQuery = query.toLowerCase();
    final rows = await (_database.select(_database.searchIndexEntryRows)
          ..where((table) => table.rootPath.equals(rootPath))
          ..orderBy([
            (table) => OrderingTerm.asc(table.depth),
            (table) => OrderingTerm.asc(table.name),
          ]))
        .get();

    return rows
        .where(
          (row) => _matches(
            row,
            normalizedQuery,
            filteredTypes,
          ),
        )
        .take(maxResults)
        .map(_toSearchResult)
        .toList(growable: false);
  }

  @override
  Future<void> replaceIndex({
    required String rootPath,
    required List<SearchResult> entries,
  }) async {
    await _database.transaction(() async {
      await clearIndex(rootPath);
      final now = DateTime.now();
      await _database.batch((batch) {
        batch.insertAll(
          _database.searchIndexEntryRows,
          [
            for (final entry in entries)
              _toCompanion(
                rootPath: rootPath,
                result: entry,
                indexedAt: now,
              ),
          ],
        );
      });
    });
  }

  @override
  Future<void> clearIndex(String rootPath) {
    return (_database.delete(_database.searchIndexEntryRows)
          ..where((table) => table.rootPath.equals(rootPath)))
        .go();
  }

  @override
  Future<void> clearIndexesForPaths(List<String> paths) async {
    if (paths.isEmpty) {
      return;
    }

    final rows = await _database.select(_database.searchIndexEntryRows).get();
    final rootPaths = {
      for (final row in rows)
        if (paths.any((path) => _pathsOverlap(row.rootPath, path)))
          row.rootPath,
    };

    for (final rootPath in rootPaths) {
      await clearIndex(rootPath);
    }
  }

  SearchResult _toSearchResult(SearchIndexEntryRow row) {
    return SearchResult(
      parentPath: row.parentPath,
      depth: row.depth,
      entry: FileSystemEntry(
        name: row.name,
        path: row.path,
        type: row.type,
        modifiedAt: row.modifiedAt,
        sizeBytes: row.sizeBytes,
        childrenCount: row.childrenCount,
      ),
    );
  }

  SearchIndexEntryRowsCompanion _toCompanion({
    required String rootPath,
    required SearchResult result,
    required DateTime indexedAt,
  }) {
    final entry = result.entry;
    return SearchIndexEntryRowsCompanion.insert(
      path: entry.path,
      rootPath: rootPath,
      parentPath: result.parentPath,
      name: entry.name,
      type: entry.type,
      modifiedAt: entry.modifiedAt,
      sizeBytes: Value(entry.sizeBytes),
      childrenCount: Value(entry.childrenCount),
      depth: result.depth,
      indexedAt: indexedAt,
    );
  }

  bool _matches(
    SearchIndexEntryRow row,
    String query,
    Set<FileSystemEntryType> filteredTypes,
  ) {
    if (filteredTypes.isNotEmpty && !filteredTypes.contains(row.type)) {
      return false;
    }
    return row.name.toLowerCase().contains(query) ||
        row.path.toLowerCase().contains(query);
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
