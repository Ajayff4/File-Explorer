import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/explorer_screen.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/media/data/repositories/media_library_repository_provider.dart';
import 'package:file_explorer/features/media/presentation/widgets/media_thumbnail.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';
import 'package:file_explorer/features/storage_permissions/domain/entities/storage_permission_state.dart';
import 'package:file_explorer/shared/formatters/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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
  ),
  archives(
    routeSegment: 'archives',
    label: 'Archives',
    type: FileSystemEntryType.archive,
    icon: Icons.inventory_2_rounded,
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

  /// Kinds served from MediaStore.Files, which on Android requires
  /// 'All files access' (MANAGE_EXTERNAL_STORAGE) to see non-media rows.
  bool get requiresAllFilesAccess =>
      this == MediaLibraryKind.documents ||
      this == MediaLibraryKind.apps ||
      this == MediaLibraryKind.archives;

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

final mediaLibraryViewModeProvider = StateProvider<ExplorerViewMode>((ref) {
  return ExplorerViewMode.grid;
});

final mediaLibraryResultsProvider =
    FutureProvider.family<List<SearchResult>, MediaLibraryRequest>(
  (ref, request) async {
    final repository = ref.watch(mediaLibraryRepositoryProvider);
    return repository.findFoldersWithMedia(
      rootPath: request.rootPath,
      type: request.kind.type,
    );
  },
);

class MediaLibraryScreen extends ConsumerWidget {
  const MediaLibraryScreen({required this.kind, super.key});

  final MediaLibraryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explorerState = ref.watch(explorerControllerProvider);
    final rootPath =
        explorerState.listing.value?.volume?.path ?? explorerState.currentPath;
    final request = (kind: kind, rootPath: rootPath);
    final resultsAsync = ref.watch(mediaLibraryResultsProvider(request));
    final sortOption = ref.watch(mediaLibrarySortOptionProvider);
    final viewMode = ref.watch(mediaLibraryViewModeProvider);

    final permission = explorerState.permission.value;
    final needsAllFilesAccess = kind.requiresAllFilesAccess &&
        permission != null &&
        permission.accessMode == StorageAccessMode.appSpecific;

    return BackButtonListener(
      onBackButtonPressed: () async {
        if (ModalRoute.of(context)?.isCurrent != true) {
          return false;
        }
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoutes.home),
          ),
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
            _MediaMoreMenu(sortOption: sortOption, viewMode: viewMode),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async =>
              ref.refresh(mediaLibraryResultsProvider(request).future),
          child: needsAllFilesAccess
              ? _AllFilesAccessPrompt(kind: kind, request: request)
              : resultsAsync.when(
                  loading: () => const _MediaLoadingState(),
                  error: (error, _) => _MediaErrorState(error: error),
                  data: (results) => _MediaResultsView(
                    kind: kind,
                    results: results,
                    sortOption: sortOption,
                    viewMode: viewMode,
                  ),
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

class _AllFilesAccessPrompt extends ConsumerWidget {
  const _AllFilesAccessPrompt({
    required this.kind,
    required this.request,
  });

  final MediaLibraryKind kind;
  final MediaLibraryRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(kind.icon, size: 48),
              const SizedBox(height: 12),
              Text(
                'All files access needed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'To browse ${kind.label.toLowerCase()} quickly, grant '
                '"All files access" for this app in system settings.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Grant access'),
                onPressed: () async {
                  await ref
                      .read(explorerControllerProvider.notifier)
                      .requestFullStorageAccess();
                  ref.invalidate(mediaLibraryResultsProvider(request));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaResultsView extends StatelessWidget {
  const _MediaResultsView({
    required this.kind,
    required this.results,
    required this.sortOption,
    required this.viewMode,
  });

  final MediaLibraryKind kind;
  final List<SearchResult> results;
  final MediaSortOption sortOption;
  final ExplorerViewMode viewMode;

  @override
  Widget build(BuildContext context) {
    final groups = _sortMediaGroups(
      _groupMediaResults(results),
      option: sortOption,
    );

    if (groups.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(kind.icon),
              title: Text('No ${kind.label.toLowerCase()} found'),
            ),
          ),
        ],
      );
    }

    if (viewMode == ExplorerViewMode.list) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 96),
        itemBuilder: (context, index) {
          final group = groups[index];
          return FileEntryListTile(
            entry: FileSystemEntry(
              name: group.name,
              path: group.path,
              type: FileSystemEntryType.folder,
              modifiedAt: group.modifiedAt,
              sizeBytes: group.totalBytes,
            ),
            badgeCount: group.count,
            onTap: () => _openMediaFolder(context, kind, group.path),
          );
        },
      );
    }

    const crossAxisCount = 3;
    const tileExtent = 148.0;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
          sliver: SliverGrid.builder(
            itemCount: groups.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: tileExtent,
              mainAxisSpacing: 10,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) => _MediaFolderTile(
              kind: kind,
              group: groups[index],
            ),
          ),
        ),
      ],
    );
  }
}

void _openMediaFolder(
    BuildContext context, MediaLibraryKind kind, String path) {
  context.push(
    '/media/${kind.routeSegment}/folder',
    extra: path,
  );
}

class _MediaMoreMenu extends ConsumerWidget {
  const _MediaMoreMenu({required this.sortOption, required this.viewMode});

  final MediaSortOption sortOption;
  final ExplorerViewMode viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_MediaMoreAction>(
      tooltip: 'More',
      icon: const Icon(Icons.more_vert_rounded),
      offset: const Offset(0, 48),
      onSelected: (action) {
        switch (action) {
          case _MediaMoreAction.switchToList:
            ref.read(mediaLibraryViewModeProvider.notifier).state =
                ExplorerViewMode.list;
          case _MediaMoreAction.switchToGrid:
            ref.read(mediaLibraryViewModeProvider.notifier).state =
                ExplorerViewMode.grid;
          case _MediaMoreAction.sortNameAsc:
            ref.read(mediaLibrarySortOptionProvider.notifier).state =
                MediaSortOption.nameAscending;
          case _MediaMoreAction.sortNameDesc:
            ref.read(mediaLibrarySortOptionProvider.notifier).state =
                MediaSortOption.nameDescending;
          case _MediaMoreAction.sortModifiedNew:
            ref.read(mediaLibrarySortOptionProvider.notifier).state =
                MediaSortOption.modifiedNewest;
          case _MediaMoreAction.sortModifiedOld:
            ref.read(mediaLibrarySortOptionProvider.notifier).state =
                MediaSortOption.modifiedOldest;
          case _MediaMoreAction.sortSizeLarge:
            ref.read(mediaLibrarySortOptionProvider.notifier).state =
                MediaSortOption.sizeLargest;
          case _MediaMoreAction.sortSizeSmall:
            ref.read(mediaLibrarySortOptionProvider.notifier).state =
                MediaSortOption.sizeSmallest;
          case _MediaMoreAction.sortTypeAsc:
            ref.read(mediaLibrarySortOptionProvider.notifier).state =
                MediaSortOption.typeAscending;
        }
      },
      itemBuilder: (context) {
        final primary = Theme.of(context).colorScheme.primary;
        return [
          PopupMenuItem(
            value: viewMode == ExplorerViewMode.list
                ? _MediaMoreAction.switchToGrid
                : _MediaMoreAction.switchToList,
            child: Row(
              children: [
                Icon(
                  viewMode == ExplorerViewMode.list
                      ? Icons.grid_view_rounded
                      : Icons.view_list_rounded,
                  color: primary,
                ),
                const SizedBox(width: 12),
                Text(
                  viewMode == ExplorerViewMode.list
                      ? 'Switch to grid view'
                      : 'Switch to list view',
                  style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 8),
          PopupMenuItem(
            value: _MediaMoreAction.sortNameAsc,
            enabled: false,
            child: Row(
              children: [
                Text(
                  'Sort by',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          _sortItem(
            icon: Icons.sort_by_alpha_rounded,
            label: 'Name (A-Z)',
            option: MediaSortOption.nameAscending,
            current: sortOption,
            primary: primary,
          ),
          _sortItem(
            icon: Icons.sort_by_alpha_rounded,
            label: 'Name (Z-A)',
            option: MediaSortOption.nameDescending,
            current: sortOption,
            primary: primary,
          ),
          _sortItem(
            icon: Icons.schedule_rounded,
            label: 'Modified (newest)',
            option: MediaSortOption.modifiedNewest,
            current: sortOption,
            primary: primary,
          ),
          _sortItem(
            icon: Icons.schedule_rounded,
            label: 'Modified (oldest)',
            option: MediaSortOption.modifiedOldest,
            current: sortOption,
            primary: primary,
          ),
          _sortItem(
            icon: Icons.data_usage_rounded,
            label: 'Size (largest)',
            option: MediaSortOption.sizeLargest,
            current: sortOption,
            primary: primary,
          ),
          _sortItem(
            icon: Icons.data_usage_rounded,
            label: 'Size (smallest)',
            option: MediaSortOption.sizeSmallest,
            current: sortOption,
            primary: primary,
          ),
          _sortItem(
            icon: Icons.category_rounded,
            label: 'Type (A-Z)',
            option: MediaSortOption.typeAscending,
            current: sortOption,
            primary: primary,
          ),
        ];
      },
    );
  }

  PopupMenuItem<_MediaMoreAction> _sortItem({
    required IconData icon,
    required String label,
    required MediaSortOption option,
    required MediaSortOption current,
    required Color primary,
  }) {
    final isActive = option == current;
    return PopupMenuItem(
      value: switch (option) {
        MediaSortOption.nameAscending => _MediaMoreAction.sortNameAsc,
        MediaSortOption.nameDescending => _MediaMoreAction.sortNameDesc,
        MediaSortOption.modifiedNewest => _MediaMoreAction.sortModifiedNew,
        MediaSortOption.modifiedOldest => _MediaMoreAction.sortModifiedOld,
        MediaSortOption.sizeLargest => _MediaMoreAction.sortSizeLarge,
        MediaSortOption.sizeSmallest => _MediaMoreAction.sortSizeSmall,
        MediaSortOption.typeAscending => _MediaMoreAction.sortTypeAsc,
      },
      child: Row(
        children: [
          Icon(icon, color: isActive ? primary : null),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isActive ? primary : null,
              fontWeight: isActive ? FontWeight.w600 : null,
            ),
          ),
          const Spacer(),
          if (isActive) Icon(Icons.check_rounded, size: 18, color: primary),
        ],
      ),
    );
  }
}

enum _MediaMoreAction {
  switchToList,
  switchToGrid,
  sortNameAsc,
  sortNameDesc,
  sortModifiedNew,
  sortModifiedOld,
  sortSizeLarge,
  sortSizeSmall,
  sortTypeAsc,
}

class _MediaFolderTile extends ConsumerWidget {
  const _MediaFolderTile({
    required this.kind,
    required this.group,
  });

  final MediaLibraryKind kind;
  final _MediaFolderGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = group.cover.entry;
    final isDocument = kind == MediaLibraryKind.documents;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openFolder(context, ref),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
          child: Column(
            children: [
              SizedBox(
                height: 96,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Center(
                        child: isDocument
                            ? const Icon(
                                Icons.insert_drive_file_rounded,
                                size: 64,
                                color: FileEntryColors.document,
                              )
                            : MediaThumbnail(
                                entry: entry,
                                fallback:
                                    fileIconForEntry(context, entry, size: 96),
                                dimension: 96,
                              ),
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Text(
                          formatCount(group.count),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                group.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFolder(BuildContext context, WidgetRef ref) {
    context.push(
      '/media/${kind.routeSegment}/folder',
      extra: group.path,
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

class _MediaFolderGroup {
  const _MediaFolderGroup({
    required this.path,
    required this.name,
    required this.results,
  });

  final String path;
  final String name;
  final List<SearchResult> results;

  SearchResult get cover => results.first;
  int get count => results.length;
  int get totalBytes =>
      results.fold(0, (total, result) => total + (result.entry.sizeBytes ?? 0));
  DateTime get modifiedAt => results
      .map((result) => result.entry.modifiedAt)
      .reduce((latest, current) => current.isAfter(latest) ? current : latest);
}

List<_MediaFolderGroup> _groupMediaResults(List<SearchResult> results) {
  final byPath = <String, List<SearchResult>>{};
  for (final result in results) {
    byPath.putIfAbsent(result.parentPath, () => []).add(result);
  }

  return [
    for (final entry in byPath.entries)
      _MediaFolderGroup(
        path: entry.key,
        name: p.basename(entry.key),
        results: _sortMediaResults(
          entry.value,
          option: MediaSortOption.modifiedNewest,
        ),
      ),
  ];
}

List<_MediaFolderGroup> _sortMediaGroups(
  List<_MediaFolderGroup> groups, {
  required MediaSortOption option,
}) {
  return groups.toList(growable: false)
    ..sort((left, right) {
      final primary = switch (option) {
        MediaSortOption.nameAscending => _compareGroupNames(left, right),
        MediaSortOption.nameDescending => _compareGroupNames(right, left),
        MediaSortOption.modifiedNewest =>
          right.modifiedAt.compareTo(left.modifiedAt),
        MediaSortOption.modifiedOldest =>
          left.modifiedAt.compareTo(right.modifiedAt),
        MediaSortOption.sizeLargest => right.totalBytes.compareTo(
            left.totalBytes,
          ),
        MediaSortOption.sizeSmallest => left.totalBytes.compareTo(
            right.totalBytes,
          ),
        MediaSortOption.typeAscending =>
          left.cover.entry.type.index.compareTo(right.cover.entry.type.index),
      };

      if (primary != 0) {
        return primary;
      }
      return _compareGroupNames(left, right);
    });
}

int _compareGroupNames(_MediaFolderGroup left, _MediaFolderGroup right) {
  final nameComparison = left.name.toLowerCase().compareTo(
        right.name.toLowerCase(),
      );
  if (nameComparison != 0) {
    return nameComparison;
  }
  return left.path.compareTo(right.path);
}

List<SearchResult> _sortMediaResults(
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
