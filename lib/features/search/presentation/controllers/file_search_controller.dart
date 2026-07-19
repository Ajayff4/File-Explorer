import 'dart:async';

import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final fileSearchControllerProvider =
    StateNotifierProvider<FileSearchController, FileSearchState>((ref) {
  return FileSearchController(
    ref.read(storageRepositoryProvider),
  );
});

class FileSearchState {
  const FileSearchState({
    this.query = '',
    this.rootPath = '',
    this.results = const [],
    this.isSearching = false,
    this.error,
  });

  final String query;
  final String rootPath;
  final List<SearchResult> results;
  final bool isSearching;
  final Object? error;

  bool get hasQuery => query.trim().isNotEmpty;

  FileSearchState copyWith({
    String? query,
    String? rootPath,
    List<SearchResult>? results,
    bool? isSearching,
    Object? error,
    bool clearError = false,
  }) {
    return FileSearchState(
      query: query ?? this.query,
      rootPath: rootPath ?? this.rootPath,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class FileSearchController extends StateNotifier<FileSearchState> {
  FileSearchController(
    this._repository, {
    Duration debounceDuration = const Duration(milliseconds: 300),
    int maxDepth = 4,
    int maxResults = 100,
  })  : _debounceDuration = debounceDuration,
        _maxDepth = maxDepth,
        _maxResults = maxResults,
        super(const FileSearchState());

  final StorageRepository _repository;
  final Duration _debounceDuration;
  final int _maxDepth;
  final int _maxResults;
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
    );

    if (trimmedQuery.isEmpty) {
      _requestSequence += 1;
      state = state.copyWith(isSearching: false);
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
      clearError: true,
    );
    if (trimmedQuery.isEmpty) {
      _requestSequence += 1;
      state = state.copyWith(isSearching: false);
      return Future.value();
    }
    return _runSearch(trimmedQuery, rootPath);
  }

  Future<void> _runSearch(String query, String rootPath) async {
    final requestId = ++_requestSequence;
    try {
      final results = await _searchDirectory(
        query.toLowerCase(),
        rootPath,
        depth: 0,
        visitedPaths: <String>{},
      );
      if (!mounted || requestId != _requestSequence) {
        return;
      }
      results.sort(_compareResults);
      state = state.copyWith(
        results: results,
        isSearching: false,
        clearError: true,
      );
    } catch (error) {
      if (!mounted || requestId != _requestSequence) {
        return;
      }
      state = state.copyWith(
        results: const [],
        isSearching: false,
        error: error,
      );
    }
  }

  Future<List<SearchResult>> _searchDirectory(
    String query,
    String path, {
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
      if (_matches(entry, query)) {
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

  bool _matches(FileSystemEntry entry, String query) {
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
