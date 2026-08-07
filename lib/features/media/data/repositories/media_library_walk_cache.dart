import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';

/// Single-pass recursive walk of a storage root, bucketed by entry type and
/// reused across media categories (documents, apps, archives, ...).
///
/// One complete walk per root — no depth or count limits. Results are served
/// from cache while fresh ([ttl]), and concurrent callers share a single
/// in-flight walk instead of walking per category.
class MediaLibraryWalkCache {
  MediaLibraryWalkCache({
    required StorageRepository storageRepository,
    Duration ttl = const Duration(minutes: 5),
    DateTime Function() now = DateTime.now,
  })  : _storageRepository = storageRepository,
        _ttl = ttl,
        _now = now;

  final StorageRepository _storageRepository;
  final Duration _ttl;
  final DateTime Function() _now;

  final Map<String, _WalkedRoot> _roots = {};
  final Map<String, Future<void>> _inFlight = {};

  Future<List<SearchResult>> resultsFor({
    required String rootPath,
    required FileSystemEntryType type,
  }) async {
    final cached = _roots[rootPath];
    if (cached == null || cached.isStale(_ttl, _now())) {
      await _refresh(rootPath);
    }
    final results = _roots[rootPath]?.results[type];
    return List.unmodifiable(results ?? const <SearchResult>[]);
  }

  void invalidate(String rootPath) {
    _roots.remove(rootPath);
  }

  Future<void> _refresh(String rootPath) {
    final existing = _inFlight[rootPath];
    if (existing != null) {
      return existing;
    }
    final future = _walkAll(rootPath);
    _inFlight[rootPath] = future;
    return future.whenComplete(() => _inFlight.remove(rootPath));
  }

  Future<void> _walkAll(String rootPath) async {
    final results = <FileSystemEntryType, List<SearchResult>>{};
    await _collect(
      path: rootPath,
      results: results,
      visitedPaths: <String>{},
    );
    _roots[rootPath] = _WalkedRoot(results, _now());
  }

  Future<void> _collect({
    required String path,
    required Map<FileSystemEntryType, List<SearchResult>> results,
    required Set<String> visitedPaths,
  }) async {
    if (!visitedPaths.add(path)) {
      return;
    }

    final listing = await _storageRepository.listDirectory(path);

    for (final entry in listing.entries) {
      if (entry.name.startsWith('.') || entry.isFolder) {
        continue;
      }
      results.putIfAbsent(entry.type, () => []).add(
            SearchResult(entry: entry, parentPath: path, depth: 0),
          );
    }

    for (final folder in listing.entries.where((entry) => entry.isFolder)) {
      if (folder.name.startsWith('.')) {
        continue;
      }
      try {
        await _collect(
          path: folder.path,
          results: results,
          visitedPaths: visitedPaths,
        );
      } on Object {
        continue;
      }
    }
  }
}

class _WalkedRoot {
  const _WalkedRoot(this.results, this.completedAt);

  final Map<FileSystemEntryType, List<SearchResult>> results;
  final DateTime completedAt;

  bool isStale(Duration ttl, DateTime now) => now.difference(completedAt) > ttl;
}
