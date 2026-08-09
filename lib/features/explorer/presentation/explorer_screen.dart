import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/entry_filters.dart';
import 'package:file_explorer/features/explorer/presentation/entry_sorting.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/favorites/presentation/controllers/favorites_controller.dart';
import 'package:file_explorer/features/media/data/platform/media_store_platform.dart';
import 'package:file_explorer/features/media/data/platform/media_store_search_results.dart';
import 'package:file_explorer/features/media/data/repositories/media_library_repository_provider.dart';
import 'package:file_explorer/features/media/presentation/local_media_actions.dart';
import 'package:file_explorer/features/media/presentation/media_viewer_screen.dart';
import 'package:file_explorer/features/media/presentation/text_file_viewer_screen.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:file_explorer/features/storage_permissions/presentation/widgets/storage_permission_card.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:file_explorer/features/transfers/presentation/transfer_visuals.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:file_explorer/shared/formatters/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

final explorerViewModeProvider = StateProvider<ExplorerViewMode>((ref) {
  return ExplorerViewMode.grid;
});

final explorerSortOptionProvider = StateProvider<ExplorerSortOption>((ref) {
  return ExplorerSortOption.nameAscending;
});

final explorerFilterTypeProvider = StateProvider<FileSystemEntryType?>((ref) {
  return null;
});

enum ExplorerViewMode { list, grid }

enum _MoreMenuAction {
  newFolder,
  newFile,
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

class ExplorerScreen extends ConsumerWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explorerState = ref.watch(explorerControllerProvider);
    final viewMode = ref.watch(explorerViewModeProvider);
    final sortOption = ref.watch(explorerSortOptionProvider);
    final filterType = ref.watch(explorerFilterTypeProvider);
    final listing = explorerState.listing;
    final permission = explorerState.permission;
    final selectedVolume = _selectedVolumeFor(explorerState);
    final favoritesState = ref.watch(favoritesControllerProvider);
    final settings = ref.watch(settingsControllerProvider).settings;
    final isFavorite = favoritesState.containsPath(explorerState.currentPath);
    final awaitingDestinationTask =
        ref.watch(transferControllerProvider).awaitingDestinationTask;
    final isSelectionMode = explorerState.isSelectionMode;
    final selectedCount = explorerState.selectedPaths.length;

    ref.listen<TransferState>(transferControllerProvider, (previous, next) {
      final previousTasks = previous?.tasks ?? const <TransferTask>[];
      final previousById = {
        for (final task in previousTasks) task.id: task.status,
      };
      final completedInCurrentFolder = next.tasks.any((task) {
        final oldStatus = previousById[task.id];
        return task.status == TransferTaskStatus.completed &&
            oldStatus != TransferTaskStatus.completed &&
            _taskTouchesPath(task, explorerState.currentPath);
      });
      if (completedInCurrentFolder) {
        ref.read(explorerControllerProvider.notifier).refresh();
      }
    });

    return BackButtonListener(
      onBackButtonPressed: () async {
        if (ModalRoute.of(context)?.isCurrent != true) {
          return false;
        }
        if (isSelectionMode) {
          ref.read(explorerControllerProvider.notifier).exitSelectionMode();
        } else if (context.canPop()) {
          context.pop();
        } else if (_canNavigateUp(explorerState)) {
          await ref
              .read(explorerControllerProvider.notifier)
              .openParentDirectory();
        } else {
          context.go(AppRoutes.home);
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: isSelectionMode
              ? IconButton(
                  tooltip: 'Exit selection',
                  onPressed: () {
                    ref
                        .read(explorerControllerProvider.notifier)
                        .exitSelectionMode();
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              : _canNavigateUp(explorerState)
                  ? IconButton(
                      tooltip: 'Up',
                      onPressed: () {
                        ref
                            .read(explorerControllerProvider.notifier)
                            .openParentDirectory();
                      },
                      icon: const Icon(Icons.arrow_upward_rounded),
                    )
                  : null,
          title: isSelectionMode
              ? Text('${formatCount(selectedCount)} selected')
              : Text(p.basename(explorerState.currentPath)),
          actions: [
            if (isSelectionMode) ...[
              IconButton(
                tooltip: 'Select all',
                onPressed: () {
                  final entries = listing.valueOrNull?.entries
                          .map((e) => e.path)
                          .toList() ??
                      [];
                  ref
                      .read(explorerControllerProvider.notifier)
                      .selectAll(entries);
                },
                icon: const Icon(Icons.select_all_rounded),
              ),
              IconButton(
                tooltip: 'Select range',
                onPressed: selectedCount >= 2
                    ? () {
                        ref
                            .read(explorerControllerProvider.notifier)
                            .selectInterval();
                      }
                    : null,
                icon: const Icon(Icons.linear_scale_rounded),
              ),
              TextButton(
                onPressed: () {
                  ref
                      .read(explorerControllerProvider.notifier)
                      .exitSelectionMode();
                },
                child: const Text('Cancel'),
              ),
            ] else ...[
              if (filterType != null)
                IconButton(
                  tooltip: 'Clear filter',
                  onPressed: () {
                    ref.read(explorerFilterTypeProvider.notifier).state = null;
                  },
                  icon: const Icon(Icons.filter_list_off_rounded),
                ),
              IconButton(
                tooltip: 'Search',
                onPressed: () => context.go(AppRoutes.search),
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
                onPressed: () {
                  ref.read(favoritesControllerProvider.notifier).toggleFavorite(
                        path: explorerState.currentPath,
                        label: _favoriteLabelFor(explorerState, selectedVolume),
                      );
                },
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () {
                  ref.read(explorerControllerProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh_rounded),
              ),
              PopupMenuButton<_MoreMenuAction>(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert_rounded),
                offset: const Offset(0, 48),
                onSelected: (action) {
                  switch (action) {
                    case _MoreMenuAction.newFolder:
                      _showCreateFolderDialog(
                        context,
                        ref,
                        () => ref
                            .read(explorerControllerProvider.notifier)
                            .refresh(),
                      );
                      break;
                    case _MoreMenuAction.newFile:
                      _showNewFileMenuSheet(context, ref);
                      break;
                    case _MoreMenuAction.switchToList:
                      ref.read(explorerViewModeProvider.notifier).state =
                          ExplorerViewMode.list;
                      break;
                    case _MoreMenuAction.switchToGrid:
                      ref.read(explorerViewModeProvider.notifier).state =
                          ExplorerViewMode.grid;
                      break;
                    case _MoreMenuAction.sortNameAsc:
                      ref.read(explorerSortOptionProvider.notifier).state =
                          ExplorerSortOption.nameAscending;
                      break;
                    case _MoreMenuAction.sortNameDesc:
                      ref.read(explorerSortOptionProvider.notifier).state =
                          ExplorerSortOption.nameDescending;
                      break;
                    case _MoreMenuAction.sortModifiedNew:
                      ref.read(explorerSortOptionProvider.notifier).state =
                          ExplorerSortOption.modifiedNewest;
                      break;
                    case _MoreMenuAction.sortModifiedOld:
                      ref.read(explorerSortOptionProvider.notifier).state =
                          ExplorerSortOption.modifiedOldest;
                      break;
                    case _MoreMenuAction.sortSizeLarge:
                      ref.read(explorerSortOptionProvider.notifier).state =
                          ExplorerSortOption.sizeLargest;
                      break;
                    case _MoreMenuAction.sortSizeSmall:
                      ref.read(explorerSortOptionProvider.notifier).state =
                          ExplorerSortOption.sizeSmallest;
                      break;
                    case _MoreMenuAction.sortTypeAsc:
                      ref.read(explorerSortOptionProvider.notifier).state =
                          ExplorerSortOption.typeAscending;
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _MoreMenuAction.newFolder,
                    child: Row(
                      children: [
                        Icon(Icons.create_new_folder_rounded),
                        SizedBox(width: 12),
                        Text('New folder'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: _MoreMenuAction.newFile,
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded),
                        SizedBox(width: 12),
                        Text('New file'),
                        Spacer(),
                        Icon(Icons.chevron_right_rounded, size: 18),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 8),
                  PopupMenuItem(
                    value: viewMode == ExplorerViewMode.list
                        ? _MoreMenuAction.switchToGrid
                        : _MoreMenuAction.switchToList,
                    child: Row(
                      children: [
                        Icon(
                          viewMode == ExplorerViewMode.list
                              ? Icons.grid_view_rounded
                              : Icons.view_list_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          viewMode == ExplorerViewMode.list
                              ? 'Switch to grid view'
                              : 'Switch to list view',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 8),
                  PopupMenuItem(
                    value: _MoreMenuAction.sortNameAsc,
                    enabled: false,
                    child: Row(
                      children: [
                        Text(
                          'Sort by',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _MoreMenuAction.sortNameAsc,
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort_by_alpha_rounded,
                          color: sortOption == ExplorerSortOption.nameAscending
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Name (A-Z)',
                          style: TextStyle(
                            color:
                                sortOption == ExplorerSortOption.nameAscending
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                            fontWeight:
                                sortOption == ExplorerSortOption.nameAscending
                                    ? FontWeight.w600
                                    : null,
                          ),
                        ),
                        const Spacer(),
                        if (sortOption == ExplorerSortOption.nameAscending)
                          Icon(Icons.check_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _MoreMenuAction.sortNameDesc,
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort_by_alpha_rounded,
                          color: sortOption == ExplorerSortOption.nameDescending
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Name (Z-A)',
                          style: TextStyle(
                            color:
                                sortOption == ExplorerSortOption.nameDescending
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                            fontWeight:
                                sortOption == ExplorerSortOption.nameDescending
                                    ? FontWeight.w600
                                    : null,
                          ),
                        ),
                        const Spacer(),
                        if (sortOption == ExplorerSortOption.nameDescending)
                          Icon(Icons.check_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _MoreMenuAction.sortModifiedNew,
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: sortOption == ExplorerSortOption.modifiedNewest
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Modified (newest)',
                          style: TextStyle(
                            color:
                                sortOption == ExplorerSortOption.modifiedNewest
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                            fontWeight:
                                sortOption == ExplorerSortOption.modifiedNewest
                                    ? FontWeight.w600
                                    : null,
                          ),
                        ),
                        const Spacer(),
                        if (sortOption == ExplorerSortOption.modifiedNewest)
                          Icon(Icons.check_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _MoreMenuAction.sortModifiedOld,
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: sortOption == ExplorerSortOption.modifiedOldest
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Modified (oldest)',
                          style: TextStyle(
                            color:
                                sortOption == ExplorerSortOption.modifiedOldest
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                            fontWeight:
                                sortOption == ExplorerSortOption.modifiedOldest
                                    ? FontWeight.w600
                                    : null,
                          ),
                        ),
                        const Spacer(),
                        if (sortOption == ExplorerSortOption.modifiedOldest)
                          Icon(Icons.check_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _MoreMenuAction.sortSizeLarge,
                    child: Row(
                      children: [
                        Icon(
                          Icons.data_usage_rounded,
                          color: sortOption == ExplorerSortOption.sizeLargest
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Size (largest)',
                          style: TextStyle(
                            color: sortOption == ExplorerSortOption.sizeLargest
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            fontWeight:
                                sortOption == ExplorerSortOption.sizeLargest
                                    ? FontWeight.w600
                                    : null,
                          ),
                        ),
                        const Spacer(),
                        if (sortOption == ExplorerSortOption.sizeLargest)
                          Icon(Icons.check_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _MoreMenuAction.sortSizeSmall,
                    child: Row(
                      children: [
                        Icon(
                          Icons.data_usage_rounded,
                          color: sortOption == ExplorerSortOption.sizeSmallest
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Size (smallest)',
                          style: TextStyle(
                            color: sortOption == ExplorerSortOption.sizeSmallest
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            fontWeight:
                                sortOption == ExplorerSortOption.sizeSmallest
                                    ? FontWeight.w600
                                    : null,
                          ),
                        ),
                        const Spacer(),
                        if (sortOption == ExplorerSortOption.sizeSmallest)
                          Icon(Icons.check_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _MoreMenuAction.sortTypeAsc,
                    child: Row(
                      children: [
                        Icon(
                          Icons.category_rounded,
                          color: sortOption == ExplorerSortOption.typeAscending
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Type (A-Z)',
                          style: TextStyle(
                            color:
                                sortOption == ExplorerSortOption.typeAscending
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                            fontWeight:
                                sortOption == ExplorerSortOption.typeAscending
                                    ? FontWeight.w600
                                    : null,
                          ),
                        ),
                        const Spacer(),
                        if (sortOption == ExplorerSortOption.typeAscending)
                          Icon(Icons.check_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        body: Column(
          children: [
            _BreadcrumbBar(path: explorerState.currentPath),
            if (awaitingDestinationTask != null)
              _PasteDestinationBanner(
                task: awaitingDestinationTask,
                destinationPath: explorerState.currentPath,
              ),
            if (listing.valueOrNull?.generatedFromSampleData ?? false)
              const _SampleDataBanner(),
            Expanded(
              child: permission.when(
                data: (permissionState) {
                  if (!permissionState.canBrowse) {
                    return StoragePermissionCard(
                      state: permissionState,
                      onRequestFullAccess: () {
                        ref
                            .read(explorerControllerProvider.notifier)
                            .requestFullStorageAccess();
                      },
                      onRetry: () {
                        ref
                            .read(explorerControllerProvider.notifier)
                            .loadInitialDirectory();
                      },
                    );
                  }

                  return listing.when(
                    data: (directoryListing) {
                      var entries = visibleExplorerEntries(
                        directoryListing.entries,
                        showHiddenFiles: settings.showHiddenFiles,
                      );

                      // Apply file type filter if set
                      if (filterType != null) {
                        // Use FutureBuilder to handle async folder filtering
                        return _FilteredEntryListView(
                          entries: entries,
                          filterType: filterType,
                          sortOption: sortOption,
                          viewMode: viewMode,
                          isSelectionMode: isSelectionMode,
                          storage: ref.watch(storageRepositoryProvider),
                          mediaStore: ref.watch(mediaStorePlatformProvider),
                        );
                      }

                      entries =
                          sortExplorerEntries(entries, option: sortOption);

                      if (entries.isEmpty) {
                        return _EmptyDirectory(filterType: filterType);
                      }
                      return viewMode == ExplorerViewMode.list
                          ? _EntryList(
                              entries: entries,
                              isSelectionMode: isSelectionMode)
                          : EntryGrid(
                              entries: entries,
                              isSelectionMode: isSelectionMode);
                    },
                    error: (error, stackTrace) => _DirectoryError(
                      error: error,
                      onRetry: () {
                        ref.read(explorerControllerProvider.notifier).refresh();
                      },
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                  );
                },
                error: (error, stackTrace) => _DirectoryError(
                  error: error,
                  onRetry: () {
                    ref
                        .read(explorerControllerProvider.notifier)
                        .loadInitialDirectory();
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _favoriteLabelFor(ExplorerState state, StorageVolume? selectedVolume) {
  final currentPath = state.currentPath;
  if (selectedVolume != null && currentPath == selectedVolume.path) {
    return selectedVolume.label;
  }
  final name = p.basename(currentPath);
  if (name.isNotEmpty && name != '.') {
    return name;
  }
  return currentPath;
}

bool _taskTouchesPath(TransferTask task, String path) {
  if (task.destinationPath == path) {
    return true;
  }
  return task.sourcePaths.any((sourcePath) => sourcePath.startsWith(path));
}

bool _canNavigateUp(ExplorerState state) {
  final volumeRoot = _selectedVolumeFor(state)?.path;
  if (volumeRoot != null) {
    return state.currentPath != volumeRoot;
  }
  return state.currentPath != p.dirname(state.currentPath);
}

StorageVolume? _selectedVolumeFor(ExplorerState state) {
  final listingVolume = state.listing.valueOrNull?.volume;
  if (listingVolume != null) {
    return listingVolume;
  }

  final volumes = state.volumes.valueOrNull ?? const <StorageVolume>[];
  for (final volume in volumes) {
    if (state.currentPath.startsWith(volume.path)) {
      return volume;
    }
  }
  return volumes.isEmpty ? null : volumes.first;
}

class _VolumeSwitcher extends ConsumerWidget {
  const _VolumeSwitcher({
    required this.volumes,
    required this.selectedVolume,
  });

  final List<StorageVolume> volumes;
  final StorageVolume? selectedVolume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = selectedVolume?.label ?? 'Files';
    if (volumes.length < 2) {
      return Text(label);
    }

    return PopupMenuButton<StorageVolume>(
      tooltip: 'Storage roots',
      onSelected: (volume) {
        // Clear any active type filter when switching storage roots so the
        // selected storage displays its full listing instead of a filtered view.
        ref.read(explorerFilterTypeProvider.notifier).state = null;
        ref.read(explorerControllerProvider.notifier).openStorageVolume(volume);
      },
      itemBuilder: (context) {
        return volumes.map((volume) {
          final isSelected = volume.path == selectedVolume?.path;
          return PopupMenuItem<StorageVolume>(
            value: volume,
            child: Row(
              children: [
                Icon(
                  volume.isPrimary
                      ? Icons.phone_android_rounded
                      : Icons.sd_storage_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        volume.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        volume.summary == null
                            ? volume.path
                            : '${formatBytes(volume.summary!.freeBytes)} free',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.check_rounded),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more_rounded),
        ],
      ),
    );
  }
}

class _BreadcrumbBar extends ConsumerWidget {
  const _BreadcrumbBar({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segments =
        path.split('/').where((segment) => segment.isNotEmpty).toList();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    _ArrowBreadcrumb(
                      label: '/',
                      onTap: () {
                        ref
                            .read(explorerControllerProvider.notifier)
                            .openDirectory('/');
                      },
                      isLast: segments.isEmpty,
                    ),
                    if (segments.isEmpty)
                      Transform.translate(
                        offset: const Offset(-12, 0),
                        child: _ArrowBreadcrumb(
                          label: path,
                          onTap: null,
                          isLast: true,
                        ),
                      )
                    else
                      ...segments.asMap().entries.map((entry) {
                        final index = entry.key;
                        final segment = entry.value;
                        final isLast = index == segments.length - 1;
                        final segmentPath =
                            '/${segments.sublist(0, index + 1).join('/')}';

                        return Transform.translate(
                          offset: const Offset(-12, 0),
                          child: _ArrowBreadcrumb(
                            label: segment,
                            onTap: isLast
                                ? null
                                : () {
                                    ref
                                        .read(
                                            explorerControllerProvider.notifier)
                                        .openDirectory(segmentPath);
                                  },
                            isLast: isLast,
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowBreadcrumb extends StatelessWidget {
  const _ArrowBreadcrumb({
    required this.label,
    required this.onTap,
    required this.isLast,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 100,
      height: 32,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: isLast
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              shape: _ArrowShape(),
              child: InkWell(
                onTap: onTap,
                customBorder: _ArrowShape(),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Center(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isLast
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                            fontWeight:
                                isLast ? FontWeight.w600 : FontWeight.normal,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowShape extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final arrowWidth = 12.0;
    return Path()
      ..moveTo(arrowWidth, 0)
      ..lineTo(rect.width - arrowWidth, 0)
      ..lineTo(rect.width, rect.height / 2)
      ..lineTo(rect.width - arrowWidth, rect.height)
      ..lineTo(arrowWidth, rect.height)
      ..lineTo(0, rect.height / 2)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

class _PasteDestinationBanner extends ConsumerWidget {
  const _PasteDestinationBanner({
    required this.task,
    required this.destinationPath,
  });

  final TransferTask task;
  final String destinationPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final details = Row(
              children: [
                Icon(iconForTransferOperation(task.operation)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${task.operation.label} "${task.displayName}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Destination: $destinationPath',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            );
            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    ref
                        .read(transferControllerProvider.notifier)
                        .cancel(task.id);
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: () {
                    ref
                        .read(transferControllerProvider.notifier)
                        .setDestination(
                          taskId: task.id,
                          destinationPath: destinationPath,
                        );
                  },
                  child: const Text('Paste here'),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  details,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: 8),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EntryList extends ConsumerWidget {
  const _EntryList({required this.entries, required this.isSelectionMode});

  final List<FileSystemEntry> entries;
  final bool isSelectionMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explorerState = ref.watch(explorerControllerProvider);
    final selectedPaths = explorerState.selectedPaths;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 96),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isSelected = selectedPaths.contains(entry.path);

        return FileEntryListTile(
          entry: entry,
          isSelectionMode: isSelectionMode,
          isSelected: isSelected,
          badgeCount: entry.isFolder ? entry.childrenCount : null,
          onToggleSelection: () {
            ref
                .read(explorerControllerProvider.notifier)
                .toggleSelection(entry.path);
          },
          onTap: _canOpenEntry(entry)
              ? () => _openEntry(context, ref, entry, entries)
              : null,
        );
      },
    );
  }
}

class EntryGrid extends ConsumerWidget {
  const EntryGrid({
    required this.entries,
    required this.isSelectionMode,
    this.shrinkWrap = false,
    this.onOpen,
    this.trailingBuilder,
    super.key,
  });

  final List<FileSystemEntry> entries;
  final bool isSelectionMode;
  final bool shrinkWrap;
  final void Function(BuildContext, WidgetRef, FileSystemEntry)? onOpen;
  final Widget? Function(BuildContext, FileSystemEntry)? trailingBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explorerState = ref.watch(explorerControllerProvider);
    final selectedPaths = explorerState.selectedPaths;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = (constraints.maxWidth / 92).floor().clamp(4, 8);

        return GridView.builder(
          shrinkWrap: shrinkWrap,
          primary: shrinkWrap ? false : null,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisExtent: 114,
            mainAxisSpacing: 10,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isSelected = selectedPaths.contains(entry.path);

            return GridEntryTile(
              entry: entry,
              isSelected: isSelected,
              isSelectionMode: isSelectionMode,
              onToggleSelection: () {
                ref
                    .read(explorerControllerProvider.notifier)
                    .toggleSelection(entry.path);
              },
              onOpen: onOpen != null
                  ? () => onOpen!(context, ref, entry)
                  : entry.isFolder
                      ? () {
                          ref
                              .read(explorerControllerProvider.notifier)
                              .openDirectory(entry.path);
                        }
                      : () => _openEntry(context, ref, entry, entries),
              trailing: trailingBuilder?.call(context, entry),
            );
          },
        );
      },
    );
  }
}

class _SampleDataBanner extends StatelessWidget {
  const _SampleDataBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.info_outline_rounded),
        title: Text(
          'Sample data',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        subtitle: const Text('Real storage is used on supported local builds.'),
      ),
    );
  }
}

class _EmptyDirectory extends StatelessWidget {
  const _EmptyDirectory({this.filterType});

  final FileSystemEntryType? filterType;

  @override
  Widget build(BuildContext context) {
    final message = filterType != null
        ? 'No ${_typeLabelFor(filterType!)} files found'
        : 'This folder is empty';

    return Center(
      child: Text(message),
    );
  }
}

String _typeLabelFor(FileSystemEntryType type) {
  return switch (type) {
    FileSystemEntryType.folder => 'Folder',
    FileSystemEntryType.image => 'Image',
    FileSystemEntryType.video => 'Video',
    FileSystemEntryType.audio => 'Audio',
    FileSystemEntryType.document => 'Document',
    FileSystemEntryType.archive => 'Archive',
    FileSystemEntryType.app => 'App',
    FileSystemEntryType.other => 'File',
  };
}

void _openEntry(
  BuildContext context,
  WidgetRef ref,
  FileSystemEntry entry,
  List<FileSystemEntry> entries,
) {
  if (entry.isFolder) {
    ref.read(explorerControllerProvider.notifier).openDirectory(entry.path);
    return;
  }
  if (_isMediaType(entry)) {
    context.push(
      AppRoutes.mediaViewer,
      extra: MediaViewerSession(entry: entry, entries: entries),
    );
  } else if (isTextFile(entry.path)) {
    context.push(
      AppRoutes.textViewer,
      extra: entry,
    );
  } else if (isZipArchive(entry)) {
    context.push(
      AppRoutes.zipViewer,
      extra: entry,
    );
  } else {
    _openWithSystem(context, entry);
  }
}

bool _isMediaType(FileSystemEntry entry) {
  return switch (entry.type) {
    FileSystemEntryType.image ||
    FileSystemEntryType.video ||
    FileSystemEntryType.audio =>
      true,
    _ => false,
  };
}

bool isZipArchive(FileSystemEntry entry) {
  if (entry.isFolder) {
    return false;
  }
  return entry.name.toLowerCase().endsWith('.zip');
}

Future<void> _openWithSystem(
    BuildContext context, FileSystemEntry entry) async {
  try {
    await openLocalFileWithSystem(entry.path);
  } on MissingPluginException {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open with is available on Android')),
    );
  } on PlatformException catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message ?? 'Could not open file')),
    );
  }
}

bool _canPreviewEntry(FileSystemEntry entry) {
  return _isMediaType(entry) || isTextFile(entry.path);
}

bool _canOpenEntry(FileSystemEntry entry) {
  return true;
}

class _DirectoryError extends StatelessWidget {
  const _DirectoryError({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_off_rounded, size: 42),
            const SizedBox(height: 12),
            Text(
              'Could not open folder',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget that handles asynchronous filtering of entries based on folder content
class _FilteredEntryListView extends StatelessWidget {
  const _FilteredEntryListView({
    required this.entries,
    required this.filterType,
    required this.sortOption,
    required this.viewMode,
    required this.isSelectionMode,
    required this.storage,
    required this.mediaStore,
  });

  final List<FileSystemEntry> entries;
  final FileSystemEntryType filterType;
  final ExplorerSortOption sortOption;
  final ExplorerViewMode viewMode;
  final bool isSelectionMode;
  final StorageRepository storage;
  final MediaStorePlatform? mediaStore;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FileSystemEntry>>(
      future: _filterEntriesByContent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredEntries = snapshot.data ?? [];
        final sorted = sortExplorerEntries(filteredEntries, option: sortOption);

        if (sorted.isEmpty) {
          return _EmptyDirectory(filterType: filterType);
        }

        return viewMode == ExplorerViewMode.list
            ? _EntryList(entries: sorted, isSelectionMode: isSelectionMode)
            : EntryGrid(entries: sorted, isSelectionMode: isSelectionMode);
      },
    );
  }

  Future<List<FileSystemEntry>> _filterEntriesByContent() async {
    final filtered = <FileSystemEntry>[];

    for (final entry in entries) {
      if (!entry.isFolder) {
        // Include files that match the filter type
        if (entry.type == filterType) {
          filtered.add(entry);
        }
      } else {
        final matchingCount = await _countMatchingEntries(entry.path);
        if (matchingCount > 0) {
          filtered.add(entry.copyWith(childrenCount: matchingCount));
        }
      }
    }

    return filtered;
  }

  Future<int> _countMatchingEntries(String path) async {
    final mediaStore = this.mediaStore;
    final mediaType =
        mediaStore == null ? null : mediaStoreMediaTypeFor(filterType);
    if (mediaStore != null && mediaType != null) {
      try {
        return await mediaStore.countMedia(mediaType, rootPath: path);
      } on Object {
        // Fall through to the filesystem walk.
      }
    }
    final counts = await storage.countEntriesByType(path);
    return counts[filterType] ?? 0;
  }
}

Future<void> _showCreateFolderDialog(
  BuildContext context,
  WidgetRef ref,
  VoidCallback onCreated,
) async {
  final name = await showDialog<String>(
    context: context,
    builder: (context) {
      return const _CreateFolderDialog();
    },
  );

  if (name == null || name.trim().isEmpty) return;

  final success = await ref
      .read(explorerControllerProvider.notifier)
      .createFolder(name.trim());

  if (context.mounted) {
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Folder "$name" created')),
      );
      onCreated();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create folder')),
      );
    }
  }
}

class _CreateFolderDialog extends StatefulWidget {
  const _CreateFolderDialog();

  @override
  State<_CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<_CreateFolderDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: 'New folder');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New folder'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Folder name',
          hintText: 'Enter folder name',
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

Future<void> _showCreateFileDialog(
  BuildContext context,
  WidgetRef ref,
  String defaultName,
  String content,
  VoidCallback onCreated,
) async {
  final name = await showDialog<String>(
    context: context,
    builder: (context) {
      return _CreateFileDialog(
        defaultName: defaultName,
        title: 'New file',
      );
    },
  );

  if (name == null || name.trim().isEmpty) return;

  final success = await ref
      .read(explorerControllerProvider.notifier)
      .createFile(name.trim(), content: content);

  if (context.mounted) {
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File "$name" created')),
      );
      onCreated();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create file')),
      );
    }
  }
}

class _CreateFileDialog extends StatefulWidget {
  const _CreateFileDialog({
    required this.defaultName,
    required this.title,
  });

  final String defaultName;
  final String title;

  @override
  State<_CreateFileDialog> createState() => _CreateFileDialogState();
}

class _CreateFileDialogState extends State<_CreateFileDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.defaultName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'File name',
          hintText: 'Enter file name',
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

void _showNewFileMenuSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'New file',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ListTile(
              leading: const _FileTypeBadge(
                extension: 'TXT',
                color: FileEntryColors.text,
              ),
              title: const Text('Text file'),
              onTap: () {
                Navigator.of(context).pop();
                _showCreateFileDialog(
                  sheetContext,
                  ref,
                  'untitled.txt',
                  '',
                  () => ref.read(explorerControllerProvider.notifier).refresh(),
                );
              },
            ),
            ListTile(
              leading: const _FileTypeBadge(
                extension: 'DOC',
                color: FileEntryColors.document,
              ),
              title: const Text('Word document'),
              onTap: () {
                Navigator.of(context).pop();
                _showCreateFileDialog(
                  sheetContext,
                  ref,
                  'untitled.docx',
                  'Document created with ES File Explorer',
                  () => ref.read(explorerControllerProvider.notifier).refresh(),
                );
              },
            ),
            ListTile(
              leading: const _FileTypeBadge(
                extension: 'XLS',
                color: FileEntryColors.spreadsheet,
              ),
              title: const Text('Excel spreadsheet'),
              onTap: () {
                Navigator.of(context).pop();
                _showCreateFileDialog(
                  sheetContext,
                  ref,
                  'untitled.xlsx',
                  'Spreadsheet created with ES File Explorer',
                  () => ref.read(explorerControllerProvider.notifier).refresh(),
                );
              },
            ),
            ListTile(
              leading: const _FileTypeBadge(
                extension: 'PPT',
                color: FileEntryColors.presentation,
              ),
              title: const Text('PowerPoint presentation'),
              onTap: () {
                Navigator.of(context).pop();
                _showCreateFileDialog(
                  sheetContext,
                  ref,
                  'untitled.pptx',
                  'Presentation created with ES File Explorer',
                  () => ref.read(explorerControllerProvider.notifier).refresh(),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

class _FileTypeBadge extends StatelessWidget {
  const _FileTypeBadge({
    required this.extension,
    required this.color,
    this.size = 24,
  });

  final String extension;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          extension,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
