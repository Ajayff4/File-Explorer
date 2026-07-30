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

enum MediaSortOption {
  nameAscending('Name A-Z'),
  nameDescending('Name Z-A'),
  modifiedNewest('Newest first'),
  modifiedOldest('Oldest first'),
  sizeLargest('Largest first'),
  sizeSmallest('Smallest first'),
  typeAscending('Type A-Z');

  const MediaSortOption(this.label);

  final String label;
}

final mediaLibrarySortOptionProvider = StateProvider<MediaSortOption>((ref) {
  return MediaSortOption.modifiedNewest;
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
    final sortOption = ref.watch(mediaLibrarySortOptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(kind.label),
        actions: [
          IconButton(
            tooltip: 'Browse folders',
            onPressed: () => _openFilteredExplorer(context, ref, rootPath),
            icon: const Icon(Icons.folder_open_rounded),
          ),
          _MediaSortMenu(selectedOption: sortOption),
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
            sortOption: sortOption,
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
    required this.sortOption,
  });

  final MediaLibraryKind kind;
  final String rootPath;
  final List<SearchResult> results;
  final MediaSortOption sortOption;

  @override
  Widget build(BuildContext context) {
    final sortedResults = sortMediaResults(results, option: sortOption);

    if (sortedResults.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MediaScopeHeader(
            kind: kind,
            rootPath: rootPath,
            count: 0,
            sortOption: sortOption,
          ),
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
      itemCount: sortedResults.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _MediaScopeHeader(
            kind: kind,
            rootPath: rootPath,
            count: sortedResults.length,
            sortOption: sortOption,
          );
        }
        return _MediaResultTile(kind: kind, result: sortedResults[index - 1]);
      },
    );
  }
}

class _MediaSortMenu extends ConsumerWidget {
  const _MediaSortMenu({required this.selectedOption});

  final MediaSortOption selectedOption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<MediaSortOption>(
      tooltip: 'Sort',
      icon: const Icon(Icons.sort_rounded),
      initialValue: selectedOption,
      onSelected: (option) {
        ref.read(mediaLibrarySortOptionProvider.notifier).state = option;
      },
      itemBuilder: (context) {
        return [
          for (final option in MediaSortOption.values)
            CheckedPopupMenuItem<MediaSortOption>(
              value: option,
              checked: option == selectedOption,
              child: Text(option.label),
            ),
        ];
      },
    );
  }
}

class _MediaScopeHeader extends StatelessWidget {
  const _MediaScopeHeader({
    required this.kind,
    required this.rootPath,
    required this.count,
    required this.sortOption,
  });

  final MediaLibraryKind kind;
  final String rootPath;
  final int count;
  final MediaSortOption sortOption;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(kind.icon),
      title: Text(count == 1 ? '1 item' : '$count items'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sorted by ${sortOption.label}'),
          Text(
            rootPath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
          fallbackIcon: iconForFileSystemEntry(entry),
          fallbackColor: colorForFileSystemEntry(context, entry),
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

List<SearchResult> sortMediaResults(
  List<SearchResult> results, {
  required MediaSortOption option,
}) {
  return results.toList(growable: false)
    ..sort((left, right) {
      final primary = switch (option) {
        MediaSortOption.nameAscending => _compareNames(left, right),
        MediaSortOption.nameDescending => _compareNames(right, left),
        MediaSortOption.modifiedNewest =>
          right.entry.modifiedAt.compareTo(left.entry.modifiedAt),
        MediaSortOption.modifiedOldest =>
          left.entry.modifiedAt.compareTo(right.entry.modifiedAt),
        MediaSortOption.sizeLargest => _compareSizes(right, left),
        MediaSortOption.sizeSmallest => _compareSizes(left, right),
        MediaSortOption.typeAscending =>
          left.entry.type.index.compareTo(right.entry.type.index),
      };

      if (primary != 0) {
        return primary;
      }
      return _compareNames(left, right);
    });
}

int _compareNames(SearchResult left, SearchResult right) {
  final nameComparison = left.entry.name.toLowerCase().compareTo(
        right.entry.name.toLowerCase(),
      );
  if (nameComparison != 0) {
    return nameComparison;
  }
  return left.entry.path.compareTo(right.entry.path);
}

int _compareSizes(SearchResult left, SearchResult right) {
  return (left.entry.sizeBytes ?? 0).compareTo(right.entry.sizeBytes ?? 0);
}
