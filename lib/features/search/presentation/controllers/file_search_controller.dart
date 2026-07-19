import 'dart:async';

import 'package:file_explorer/features/search/data/repositories/search_index_store_provider.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';
import 'package:file_explorer/features/search/domain/repositories/search_index_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final fileSearchControllerProvider =
    StateNotifierProvider<FileSearchController, FileSearchState>((ref) {
  return FileSearchController(
    ref.read(storageRepositoryProvider),
    indexStore: ref.read(searchIndexStoreProvider),
  );
});

class FileSearchState {
  const FileSearchState({
    this.query = '',
    this.rootPath = '',
    this.filteredTypes = const {},
    this.results = const [],
    this.isSearching = false,
    this.isIndexing = false,
    this.error,
  });

  final String query;
  final String rootPath;
  final Set<FileSystemEntryType> filteredTypes;
  final List<SearchResult> results;
  final bool isSearching;
  final bool isIndexing;
  final Object? error;

  bool get hasQuery => query.trim().isNotEmpty;

  FileSearchState copyWith({
    String? query,
    String? rootPath,
    Set<FileSystemEntryType>? filteredTypes,
    List<SearchResult>? results,
    bool? isSearching,
    bool? isIndexing,
    Object? error,
    bool clearError = false,
  }) {
    return FileSearchState(
      query: query ?? this.query,
      rootPath: rootPath ?? this.rootPath,
      filteredTypes: filteredTypes ?? this.filteredTypes,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      isIndexing: isIndexing ?? this.isIndexing,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class FileSearchController extends StateNotifier<FileSearchState> {
  FileSearchController(
    this._repository, {
    SearchIndexStore? indexStore,
    Duration debounceDuration = const Duration(milliseconds: 300),
    int maxDepth = 4,
    int maxResults = 100,
    int maxIndexedEntries = 1000,
  })  : _indexStore = indexStore,
        _debounceDuration = debounceDuration,
        _maxDepth = maxDepth,
        _maxResults = maxResults,
        _maxIndexedEntries = maxIndexedEntries,
        super(const FileSearchState());

  final StorageRepository _repository;
  final SearchIndexStore? _indexStore;
  final Duration _debounceDuration;
  final int _maxDepth;
  final int _maxResults;
  final int _maxIndexedEntries;
  Timer? _debounceTimer;
  int _requestSequence = 0;

  void setQuery({
    required String query,
    required String rootPath,
  }) {
    _debounceTimer?.cancel();
    final trimmedQuery = query.trim();
    state = state.copyWith(
      query: query,
      rootPath: rootPath,
      clearError: true,
      results: trimmedQuery.isEmpty ? const [] : state.results,
      isSearching: trimmedQuery.isNotEmpty,
      isIndexing: false,
    );

    if (trimmedQuery.isEmpty) {
      _requestSequence += 1;
      state = state.copyWith(isSearching: false, isIndexing: false);
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () {
      unawaited(_runSearch(trimmedQuery, rootPath));
    });
  }

  Future<void> searchNow({
    required String query,
    required String rootPath,
  }) {
    _debounceTimer?.cancel();
    final trimmedQuery = query.trim();
    state = state.copyWith(
      query: query,
      rootPath: rootPath,
      results: trimmedQuery.isEmpty ? const [] : state.results,
      isSearching: trimmedQuery.isNotEmpty,
      isIndexing: false,
      clearError: true,
    );
    if (trimmedQuery.isEmpty) {
      _requestSequence += 1;
      state = state.copyWith(isSearching: false, isIndexing: false);
      return Future.value();
    }
    return _runSearch(trimmedQuery, rootPath);
  }

  Future<void> setFilteredTypes({
    required Set<FileSystemEntryType> filteredTypes,
    required String rootPath,
  }) {
    final copiedTypes = Set<FileSystemEntryType>.unmodifiable(filteredTypes);
    state = state.copyWith(
      rootPath: rootPath,
      filteredTypes: copiedTypes,
      clearError: true,
    );
    return searchNow(query: state.query, rootPath: rootPath);
  }

  Future<void> reindex({
    required String rootPath,
  }) async {
    _debounceTimer?.cancel();
    _requestSequence += 1;
    final query = state.query.trim();
    state = state.copyWith(
      rootPath: rootPath,
      isSearching: query.isNotEmpty,
      isIndexing: true,
      results: query.isEmpty ? const [] : state.results,
      clearError: true,
    );

    final indexStore = _indexStore;
    if (indexStore != null) {
      await indexStore.clearIndex(rootPath);
    }

    if (query.isEmpty) {
      state = state.copyWith(isSearching: false, isIndexing: false);
      return;
    }

    await _runSearch(query, rootPath);
  }

  Future<void> _runSearch(String query, String rootPath) async {
    final requestId = ++_requestSequence;
    final filteredTypes = state.filteredTypes;
    try {
      final results = await _searchIndexedOrLive(
        query: query.toLowerCase(),
        rootPath: rootPath,
        filteredTypes: filteredTypes,
        requestId: requestId,
      );
      if (!mounted || requestId != _requestSequence) {
        return;
      }
      results.sort(_compareResults);
      state = state.copyWith(
        results: results,
        isSearching: false,
        isIndexing: false,
        clearError: true,
      );
    } catch (error) {
      if (!mounted || requestId != _requestSequence) {
        return;
      }
      state = state.copyWith(
        results: const [],
        isSearching: false,
        isIndexing: false,
        error: error,
      );
    }
  }

  Future<List<SearchResult>> _searchIndexedOrLive({
    required String query,
    required String rootPath,
    required Set<FileSystemEntryType> filteredTypes,
    required int requestId,
  }) async {
    final indexStore = _indexStore;
    if (indexStore == null) {
      return _searchDirectory(
        query,
        rootPath,
        filteredTypes: filteredTypes,
        depth: 0,
        visitedPaths: <String>{},
      );
    }

    if (!await indexStore.hasIndex(rootPath)) {
      if (!mounted || requestId != _requestSequence) {
        return const [];
      }
      state = state.copyWith(isIndexing: true);
      final entries = await _collectIndexEntries(
        rootPath,
        depth: 0,
        visitedPaths: <String>{},
      );
      entries.sort(_compareResults);
      await indexStore.replaceIndex(rootPath: rootPath, entries: entries);
    }

    final results = await indexStore.search(
      rootPath: rootPath,
      query: query,
      filteredTypes: filteredTypes,
      maxResults: _maxResults,
    );
    results.sort(_compareResults);
    return results;
  }

  Future<List<SearchResult>> _searchDirectory(
    String query,
    String path, {
    required Set<FileSystemEntryType> filteredTypes,
    required int depth,
    required Set<String> visitedPaths,
  }) async {
    if (depth > _maxDepth || visitedPaths.contains(path)) {
      return const [];
    }
    visitedPaths.add(path);

    final listing = await _repository.listDirectory(path);
    final results = <SearchResult>[];

    for (final entry in listing.entries) {
      if (_matches(entry, query, filteredTypes)) {
        results.add(
          SearchResult(
            entry: entry,
            parentPath: path,
            depth: depth,
          ),
        );
      }
      if (results.length >= _maxResults) {
        return results;
      }
    }

    for (final folder in listing.entries.where((entry) => entry.isFolder)) {
      if (results.length >= _maxResults) {
        break;
      }
      try {
        results.addAll(
          await _searchDirectory(
            query,
            folder.path,
            filteredTypes: filteredTypes,
            depth: depth + 1,
            visitedPaths: visitedPaths,
          ),
        );
      } on Object {
        continue;
      }
    }

    return results.length > _maxResults
        ? results.take(_maxResults).toList(growable: false)
        : results;
  }

  Future<List<SearchResult>> _collectIndexEntries(
    String path, {
    required int depth,
    required Set<String> visitedPaths,
  }) async {
    if (depth > _maxDepth || visitedPaths.contains(path)) {
      return const [];
    }
    visitedPaths.add(path);

    final listing = await _repository.listDirectory(path);
    final results = <SearchResult>[
      for (final entry in listing.entries)
        SearchResult(
          entry: entry,
          parentPath: path,
          depth: depth,
        ),
    ];

    for (final folder in listing.entries.where((entry) => entry.isFolder)) {
      if (results.length >= _maxIndexedEntries) {
        break;
      }
      try {
        results.addAll(
          await _collectIndexEntries(
            folder.path,
            depth: depth + 1,
            visitedPaths: visitedPaths,
          ),
        );
      } on Object {
        continue;
      }
    }

    return results.length > _maxIndexedEntries
        ? results.take(_maxIndexedEntries).toList(growable: false)
        : results;
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

  int _compareResults(SearchResult left, SearchResult right) {
    if (left.entry.isFolder != right.entry.isFolder) {
      return left.entry.isFolder ? -1 : 1;
    }
    if (left.depth != right.depth) {
      return left.depth.compareTo(right.depth);
    }
    return left.entry.name.toLowerCase().compareTo(
          right.entry.name.toLowerCase(),
        );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

String parentPathForSearchResult(SearchResult result) {
  return result.entry.isFolder
      ? result.entry.path
      : p.dirname(result.entry.path);
}
