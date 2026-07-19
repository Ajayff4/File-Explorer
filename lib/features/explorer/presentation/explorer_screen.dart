import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/entry_actions_button.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/storage_permissions/presentation/widgets/storage_permission_card.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:file_explorer/features/transfers/presentation/transfer_visuals.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final explorerViewModeProvider = StateProvider<ExplorerViewMode>((ref) {
  return ExplorerViewMode.list;
});

enum ExplorerViewMode { list, grid }

class ExplorerScreen extends ConsumerWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explorerState = ref.watch(explorerControllerProvider);
    final viewMode = ref.watch(explorerViewModeProvider);
    final listing = explorerState.listing;
    final permission = explorerState.permission;
    final selectedVolume = _selectedVolumeFor(explorerState);
    final awaitingDestinationTask =
        ref.watch(transferControllerProvider).awaitingDestinationTask;

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

    return Scaffold(
      appBar: AppBar(
        leading: _canNavigateUp(explorerState)
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
        title: explorerState.volumes.when(
          data: (volumes) => _VolumeSwitcher(
            volumes: volumes,
            selectedVolume: selectedVolume,
          ),
          error: (error, stackTrace) => const Text('Files'),
          loading: () => const Text('Files'),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(explorerControllerProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
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
                    final entries = directoryListing.entries;
                    if (entries.isEmpty) {
                      return const _EmptyDirectory();
                    }
                    return viewMode == ExplorerViewMode.list
                        ? _EntryList(entries: entries)
                        : _EntryGrid(entries: entries);
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
    );
  }
}

bool _taskTouchesPath(TransferTask task, String path) {
  if (task.destinationPath == path) {
    return true;
  }
  return task.sourcePaths.any((sourcePath) => sourcePath.startsWith(path));
}

bool _canNavigateUp(ExplorerState state) {
  final volumeRoot = state.listing.valueOrNull?.volume?.path;
  return volumeRoot != null && state.currentPath != volumeRoot;
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

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final segments = path.split('/').where((segment) => segment.isNotEmpty);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Icon(Icons.home_rounded, size: 18),
              const SizedBox(width: 8),
              if (segments.isEmpty)
                Text(path, style: Theme.of(context).textTheme.labelLarge)
              else
                ...segments.expand(
                  (segment) => [
                    Text(segment,
                        style: Theme.of(context).textTheme.labelLarge),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
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
  const _EntryList({required this.entries});

  final List<FileSystemEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          child: ListTile(
            leading: Icon(iconForFileSystemEntryType(entry.type)),
            title:
                Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(detailForFileSystemEntry(entry)),
            onTap: entry.isFolder
                ? () {
                    // Folder navigation is routed through the controller so
                    // permission and provider errors stay centralized.
                    ref
                        .read(explorerControllerProvider.notifier)
                        .openDirectory(entry.path);
                  }
                : null,
            trailing: EntryActionsButton(entry: entry),
          ),
        );
      },
    );
  }
}

class _EntryGrid extends ConsumerWidget {
  const _EntryGrid({required this.entries});

  final List<FileSystemEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        return Card(
          child: Stack(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: entry.isFolder
                    ? () {
                        ref
                            .read(explorerControllerProvider.notifier)
                            .openDirectory(entry.path);
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
  const _EmptyDirectory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('This folder is empty'),
    );
  }
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
