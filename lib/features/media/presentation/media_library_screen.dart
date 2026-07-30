import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/explorer_screen.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/media/presentation/widgets/media_thumbnail.dart';
import 'package:file_explorer/features/recents/presentation/controllers/recents_controller.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

enum MediaLibraryKind {
  images(
    routeSegment: 'images',
    label: 'Images',
    type: FileSystemEntryType.image,
    icon: Icons.image_rounded,
  ),
  videos(
    routeSegment: 'videos',
    label: 'Videos',
    type: FileSystemEntryType.video,
    icon: Icons.movie_rounded,
  ),
  audio(
    routeSegment: 'audio',
    label: 'Audio',
    type: FileSystemEntryType.audio,
    icon: Icons.music_note_rounded,
  ),
  documents(
    routeSegment: 'documents',
    label: 'Documents',
    type: FileSystemEntryType.document,
    icon: Icons.description_rounded,
  ),
  apps(
    routeSegment: 'apps',
    label: 'Apps',
    type: FileSystemEntryType.app,
    icon: Icons.apps_rounded,
  );

  const MediaLibraryKind({
    required this.routeSegment,
    required this.label,
    required this.type,
    required this.icon,
  });

  final String routeSegment;
  final String label;
  final FileSystemEntryType type;
  final IconData icon;

  static MediaLibraryKind fromRouteSegment(String? segment) {
    return MediaLibraryKind.values.firstWhere(
      (kind) => kind.routeSegment == segment,
      orElse: () => MediaLibraryKind.images,
    );
  }
}

typedef MediaLibraryRequest = ({
  MediaLibraryKind kind,
  String rootPath,
});

final mediaLibraryResultsProvider =
    FutureProvider.family<List<SearchResult>, MediaLibraryRequest>(
  (ref, request) async {
    final repository = ref.watch(storageRepositoryProvider);
    final results = <SearchResult>[];
    await _collectMediaResults(
      repository: repository,
      path: request.rootPath,
      type: request.kind.type,
      results: results,
      visitedPaths: <String>{},
      depth: 0,
      maxDepth: 5,
      maxResults: 300,
    );
    results.sort(_compareResults);
    return results;
  },
);

class MediaLibraryScreen extends ConsumerWidget {
  const MediaLibraryScreen({required this.kind, super.key});

  final MediaLibraryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explorerState = ref.watch(explorerControllerProvider);
    final rootPath = explorerState.listing.valueOrNull?.volume?.path ??
        explorerState.currentPath;
    final request = (kind: kind, rootPath: rootPath);
    final resultsAsync = ref.watch(mediaLibraryResultsProvider(request));

    return Scaffold(
      appBar: AppBar(
        title: Text(kind.label),
        actions: [
          IconButton(
            tooltip: 'Browse folders',
            onPressed: () => _openFilteredExplorer(context, ref, rootPath),
            icon: const Icon(Icons.folder_open_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                ref.invalidate(mediaLibraryResultsProvider(request)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.refresh(mediaLibraryResultsProvider(request).future),
        child: resultsAsync.when(
          loading: () => const _MediaLoadingState(),
          error: (error, _) => _MediaErrorState(error: error),
          data: (results) => _MediaResultsView(
            kind: kind,
            rootPath: rootPath,
            results: results,
          ),
        ),
      ),
    );
  }

  void _openFilteredExplorer(
    BuildContext context,
    WidgetRef ref,
    String rootPath,
  ) {
    ref.read(explorerFilterTypeProvider.notifier).state = kind.type;
    ref.read(explorerControllerProvider.notifier).openDirectory(rootPath);
    context.go(AppRoutes.explorer);
  }
}

class _MediaResultsView extends StatelessWidget {
  const _MediaResultsView({
    required this.kind,
    required this.rootPath,
    required this.results,
  });

  final MediaLibraryKind kind;
  final String rootPath;
  final List<SearchResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MediaScopeHeader(kind: kind, rootPath: rootPath, count: 0),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(kind.icon),
              title: Text('No ${kind.label.toLowerCase()} found'),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _MediaScopeHeader(
            kind: kind,
            rootPath: rootPath,
            count: results.length,
          );
        }
        return _MediaResultTile(kind: kind, result: results[index - 1]);
      },
    );
  }
}

class _MediaScopeHeader extends StatelessWidget {
  const _MediaScopeHeader({
    required this.kind,
    required this.rootPath,
    required this.count,
  });

  final MediaLibraryKind kind;
  final String rootPath;
  final int count;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(kind.icon),
      title: Text(count == 1 ? '1 item' : '$count items'),
      subtitle: Text(
        rootPath,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MediaResultTile extends ConsumerWidget {
  const _MediaResultTile({required this.kind, required this.result});

  final MediaLibraryKind kind;
  final SearchResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = result.entry;

    return Card(
      child: ListTile(
        leading: MediaThumbnail(
          entry: entry,
          fallbackIcon: iconForFileSystemEntryType(entry.type),
        ),
        title: Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          result.parentPath,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(formatBytes(entry.sizeBytes ?? 0)),
        onTap: () {
          final settings = ref.read(settingsControllerProvider).settings;
          if (!settings.showFoldersOnlyInHistory) {
            ref.read(recentsControllerProvider.notifier).recordLocation(
                  path: entry.path,
                  label: entry.name,
                  isFolder: false,
                );
          }
          ref.read(explorerFilterTypeProvider.notifier).state = kind.type;
          ref.read(explorerControllerProvider.notifier).openDirectory(
                p.dirname(entry.path),
                recordRecent: settings.showFoldersOnlyInHistory,
              );
          context.go(AppRoutes.explorer);
        },
      ),
    );
  }
}

class _MediaLoadingState extends StatelessWidget {
  const _MediaLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _MediaErrorState extends StatelessWidget {
  const _MediaErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.error_outline_rounded),
            title: const Text('Could not load library'),
            subtitle: Text('$error'),
          ),
        ),
      ],
    );
  }
}

Future<void> _collectMediaResults({
  required StorageRepository repository,
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

  final listing = await repository.listDirectory(path);

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
      await _collectMediaResults(
        repository: repository,
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

int _compareResults(SearchResult left, SearchResult right) {
  if (left.depth != right.depth) {
    return left.depth.compareTo(right.depth);
  }
  return left.entry.name.toLowerCase().compareTo(
        right.entry.name.toLowerCase(),
      );
}
