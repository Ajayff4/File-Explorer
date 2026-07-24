import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/entry_filters.dart';
import 'package:file_explorer/features/explorer/presentation/entry_sorting.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/entry_actions_button.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/favorites/presentation/controllers/favorites_controller.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:file_explorer/features/storage_permissions/presentation/widgets/storage_permission_card.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:file_explorer/features/transfers/presentation/transfer_visuals.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

final explorerViewModeProvider = StateProvider<ExplorerViewMode>((ref) {
  return ExplorerViewMode.list;
});

final explorerSortOptionProvider = StateProvider<ExplorerSortOption>((ref) {
  return ExplorerSortOption.nameAscending;
});

final explorerFilterTypeProvider = StateProvider<FileSystemEntryType?>((ref) {
  return null;
});

enum ExplorerViewMode { list, grid }

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

    return PopScope(
      canPop: !_canNavigateUp(explorerState) && !isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (isSelectionMode) {
            ref.read(explorerControllerProvider.notifier).exitSelectionMode();
          } else {
            ref.read(explorerControllerProvider.notifier).openParentDirectory();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: isSelectionMode
              ? IconButton(
                  tooltip: 'Exit selection',
                  onPressed: () {
                    ref.read(explorerControllerProvider.notifier).exitSelectionMode();
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
              ? Text('$selectedCount selected')
              : explorerState.volumes.when(
                  data: (volumes) => _VolumeSwitcher(
                    volumes: volumes,
                    selectedVolume: selectedVolume,
                  ),
                  error: (error, stackTrace) => const Text('Files'),
                  loading: () => const Text('Files'),
                ),
          actions: [
            if (isSelectionMode) ...[
              IconButton(
                tooltip: 'Select all',
                onPressed: () {
                  final entries = listing.valueOrNull?.entries.map((e) => e.path).toList() ?? [];
                  ref.read(explorerControllerProvider.notifier).selectAll(entries);
                },
                icon: const Icon(Icons.select_all_rounded),
              ),
              IconButton(
                tooltip: 'Clear selection',
                onPressed: () {
                  ref.read(explorerControllerProvider.notifier).clearSelection();
                },
                icon: const Icon(Icons.clear_rounded),
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
              _SortMenu(selectedOption: sortOption),
              SegmentedButton<ExplorerViewMode>(
                segments: const [
                  ButtonSegment(
                    value: ExplorerViewMode.list,
                    icon: Icon(Icons.view_list_rounded),
                    tooltip: 'List view',
                  ),
                  ButtonSegment(
                    value: ExplorerViewMode.grid,
                    icon: Icon(Icons.grid_view_rounded),
                    tooltip: 'Grid view',
                  ),
                ],
                selected: {viewMode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  ref.read(explorerViewModeProvider.notifier).state =
                      selection.first;
                },
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
                      entries = entries.where((entry) => entry.type == filterType).toList();
                    }
                    
                    entries = sortExplorerEntries(entries, option: sortOption);
                    
                    if (entries.isEmpty) {
                      return _EmptyDirectory(filterType: filterType);
                    }
                    return viewMode == ExplorerViewMode.list
                        ? _EntryList(entries: entries, isSelectionMode: isSelectionMode)
                        : _EntryGrid(entries: entries, isSelectionMode: isSelectionMode);
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
          if (isSelectionMode)
            _SelectionActionBar(
              selectedCount: selectedCount,
              onCopy: () {
                final selectedPaths = explorerState.selectedPaths.toList();
                final displayName = selectedCount == 1 
                    ? selectedPaths.first 
                    : '$selectedCount items';
                ref.read(transferControllerProvider.notifier).queueOperation(
                      operation: TransferOperation.copy,
                      sourcePaths: selectedPaths,
                      displayName: displayName,
                    );
                ref.read(explorerControllerProvider.notifier).exitSelectionMode();
              },
              onMove: () {
                final selectedPaths = explorerState.selectedPaths.toList();
                final displayName = selectedCount == 1 
                    ? selectedPaths.first 
                    : '$selectedCount items';
                ref.read(transferControllerProvider.notifier).queueOperation(
                      operation: TransferOperation.move,
                      sourcePaths: selectedPaths,
                      displayName: displayName,
                    );
                ref.read(explorerControllerProvider.notifier).exitSelectionMode();
              },
              onDelete: () {
                final selectedPaths = explorerState.selectedPaths.toList();
                final displayName = selectedCount == 1 
                    ? selectedPaths.first 
                    : '$selectedCount items';
                ref.read(transferControllerProvider.notifier).queueOperation(
                      operation: TransferOperation.delete,
                      sourcePaths: selectedPaths,
                      displayName: displayName,
                    );
                ref.read(explorerControllerProvider.notifier).exitSelectionMode();
              },
            ),
        ],
      ),
      ),
    );
  }
}

class _SortMenu extends ConsumerWidget {
  const _SortMenu({required this.selectedOption});

  final ExplorerSortOption selectedOption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<ExplorerSortOption>(
      tooltip: 'Sort',
      icon: const Icon(Icons.sort_rounded),
      initialValue: selectedOption,
      onSelected: (option) {
        ref.read(explorerSortOptionProvider.notifier).state = option;
      },
      itemBuilder: (context) {
        return [
          for (final option in ExplorerSortOption.values)
            CheckedPopupMenuItem<ExplorerSortOption>(
              value: option,
              checked: option == selectedOption,
              child: Text(option.label),
            ),
        ];
      },
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
    final segments = path.split('/').where((segment) => segment.isNotEmpty).toList();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  ref.read(explorerControllerProvider.notifier).openDirectory('/');
                },
                child: const Icon(Icons.home_rounded, size: 18),
              ),
              const SizedBox(width: 8),
              if (segments.isEmpty)
                Text(path, style: Theme.of(context).textTheme.labelLarge)
              else
                ...segments.asMap().entries.expand((entry) {
                  final index = entry.key;
                  final segment = entry.value;
                  final isLast = index == segments.length - 1;
                  final segmentPath = '/' + segments.sublist(0, index + 1).join('/');
                  
                  return [
                    InkWell(
                      onTap: isLast 
                          ? null 
                          : () {
                              ref.read(explorerControllerProvider.notifier).openDirectory(segmentPath);
                            },
                      child: Text(
                        segment,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: isLast 
                                  ? null 
                                  : Theme.of(context).colorScheme.primary,
                              decoration: isLast ? null : TextDecoration.underline,
                            ),
                      ),
                    ),
                    if (!isLast) const Icon(Icons.chevron_right_rounded),
                  ];
                }),
            ],
          ),
        ),
      ),
    );
  }
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
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isSelected = selectedPaths.contains(entry.path);
        
        return Card(
          color: isSelected 
              ? Theme.of(context).colorScheme.secondaryContainer 
              : null,
          child: ListTile(
            leading: isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) {
                      ref.read(explorerControllerProvider.notifier).toggleSelection(entry.path);
                    },
                  )
                : Icon(iconForFileSystemEntryType(entry.type)),
            title:
                Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(detailForFileSystemEntry(entry)),
            onTap: isSelectionMode
                ? () {
                    ref.read(explorerControllerProvider.notifier).toggleSelection(entry.path);
                  }
                : entry.isFolder
                    ? () {
                        // Folder navigation is routed through the controller so
                        // permission and provider errors stay centralized.
                        ref
                            .read(explorerControllerProvider.notifier)
                            .openDirectory(entry.path);
                      }
                    : null,
            onLongPress: isSelectionMode
                ? null
                : () {
                    ref.read(explorerControllerProvider.notifier).toggleSelection(entry.path);
                  },
            trailing: isSelectionMode ? null : EntryActionsButton(entry: entry),
          ),
        );
      },
    );
  }
}

class _EntryGrid extends ConsumerWidget {
  const _EntryGrid({required this.entries, required this.isSelectionMode});

  final List<FileSystemEntry> entries;
  final bool isSelectionMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explorerState = ref.watch(explorerControllerProvider);
    final selectedPaths = explorerState.selectedPaths;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isSelected = selectedPaths.contains(entry.path);
        
        return Card(
          color: isSelected 
              ? Theme.of(context).colorScheme.secondaryContainer 
              : null,
          child: Stack(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: isSelectionMode
                    ? () {
                        ref.read(explorerControllerProvider.notifier).toggleSelection(entry.path);
                      }
                    : entry.isFolder
                        ? () {
                            ref
                                .read(explorerControllerProvider.notifier)
                                .openDirectory(entry.path);
                          }
                        : null,
                onLongPress: isSelectionMode
                    ? null
                    : () {
                        ref.read(explorerControllerProvider.notifier).toggleSelection(entry.path);
                      },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSelectionMode)
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) {
                            ref.read(explorerControllerProvider.notifier).toggleSelection(entry.path);
                          },
                        )
                      else
                        Icon(iconForFileSystemEntryType(entry.type), size: 36),
                      const SizedBox(height: 12),
                      Text(
                        entry.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        detailForFileSystemEntry(entry),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isSelectionMode)
                Positioned(
                  top: 4,
                  right: 4,
                  child: EntryActionsButton(entry: entry),
                ),
            ],
          ),
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

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.selectedCount,
    required this.onCopy,
    required this.onMove,
    required this.onDelete,
  });

  final int selectedCount;
  final VoidCallback onCopy;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$selectedCount selected',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Copy',
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Move',
                onPressed: onMove,
                icon: const Icon(Icons.drive_file_move_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
