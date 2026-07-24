import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/explorer_screen.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/favorites/domain/entities/favorite_location.dart';
import 'package:file_explorer/features/favorites/presentation/controllers/favorites_controller.dart';
import 'package:file_explorer/features/recents/domain/entities/recent_location.dart';
import 'package:file_explorer/features/recents/presentation/controllers/recents_controller.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

// Provider for category counts in storage root
final categoryCounts = FutureProvider.family<Map<FileSystemEntryType, int>, String>((ref, rootPath) async {
  final repository = ref.watch(storageRepositoryProvider);
  return repository.countEntriesByType(rootPath);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explorerState = ref.watch(explorerControllerProvider);
    final favoritesState = ref.watch(favoritesControllerProvider);
    final recentsState = ref.watch(recentsControllerProvider);
    final settings = ref.watch(settingsControllerProvider).settings;
    final transferState = ref.watch(transferControllerProvider);
    final summary = explorerState.summary.valueOrNull;
    final visibleRecents = settings.showFoldersOnlyInHistory
        ? recentsState.locations.where((recent) => recent.isFolder).toList()
        : recentsState.locations;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('File Explorer'),
          actions: [
            IconButton(
              tooltip: 'Search',
              onPressed: () => context.go(AppRoutes.search),
              icon: const Icon(Icons.search_rounded),
            ),
            IconButton(
              tooltip: 'More',
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.list(
            children: [
              _StoragePanel(summary: summary),
              const SizedBox(height: 16),
              const _ShortcutGrid(),
              if (settings.showTransferStation) ...[
                const SizedBox(height: 16),
                _TransferStationTile(state: transferState),
              ],
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Favorites',
                actionLabel: 'Browse',
                onPressed: () => context.go(AppRoutes.explorer),
              ),
              const SizedBox(height: 8),
              if (favoritesState.isLoading)
                const LinearProgressIndicator()
              else if (favoritesState.locations.isEmpty)
                const _EmptyFavoritesTile()
              else
                ...favoritesState.locations.take(5).map(
                      (favorite) => _FavoriteLocationTile(
                        favorite: favorite,
                      ),
                    ),
              const SizedBox(height: 20),
              _SectionHeader(
                title: settings.showFoldersOnlyInHistory
                    ? 'Recent folders'
                    : 'Recent',
                actionLabel: visibleRecents.isEmpty ? 'Browse' : 'Clear',
                onPressed: visibleRecents.isEmpty
                    ? () => context.go(AppRoutes.explorer)
                    : () {
                        ref
                            .read(recentsControllerProvider.notifier)
                            .clearRecents();
                      },
              ),
              const SizedBox(height: 8),
              if (recentsState.isLoading)
                const LinearProgressIndicator()
              else if (visibleRecents.isEmpty)
                const _EmptyRecentsTile()
              else
                ...visibleRecents.take(5).map(
                      (recent) => _RecentLocationTile(
                        recent: recent,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransferStationTile extends StatelessWidget {
  const _TransferStationTile({required this.state});

  final TransferState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.sync_alt_rounded),
        title: const Text('Transfer station'),
        subtitle: Text(
          '${state.pendingCount} pending - ${state.finishedCount} finished - ${state.failedCount} failed',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.go(AppRoutes.transfers),
      ),
    );
  }
}

class _StoragePanel extends ConsumerWidget {
  const _StoragePanel({required this.summary});

  final StorageSummary? summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final storageSummary = summary;
    final explorerState = ref.watch(explorerControllerProvider);
    final selectedVolume = _selectedVolumeFor(explorerState);

        return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Reset to storage root when clicking from home
          final rootPath = selectedVolume?.path ?? '/';
          // Clear any active type filter so the storage root shows all entries
          ref.read(explorerFilterTypeProvider.notifier).state = null;
          ref.read(explorerControllerProvider.notifier).openDirectory(rootPath);
          context.go(AppRoutes.explorer);
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.phone_android_rounded, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      storageSummary?.label ?? 'Storage',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    storageSummary == null
                        ? 'Loading'
                        : '${formatBytes(storageSummary.freeBytes)} free',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: storageSummary?.usedFraction,
                  minHeight: 10,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                storageSummary == null
                    ? 'Checking available storage'
                    : '${formatBytes(storageSummary.usedBytes)} used of ${formatBytes(storageSummary.totalBytes)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
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

class _ShortcutGrid extends ConsumerWidget {
  const _ShortcutGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explorerState = ref.watch(explorerControllerProvider);
    final selectedVolume = _selectedVolumeFor(explorerState);
    final rootPath = selectedVolume?.path ?? '/';
    final countsAsync = ref.watch(categoryCounts(rootPath));

    const shortcuts = [
      _Shortcut('Images', Icons.image_outlined, FileSystemEntryType.image),
      _Shortcut('Video', Icons.movie_outlined, FileSystemEntryType.video),
      _Shortcut('Audio', Icons.music_note_outlined, FileSystemEntryType.audio),
      _Shortcut('Apps', Icons.apps_outlined, FileSystemEntryType.app),
      _Shortcut('Archives', Icons.inventory_2_outlined, FileSystemEntryType.archive),
      _Shortcut('Documents', Icons.description_outlined, FileSystemEntryType.document),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 920 ? 6 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shortcuts.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: columns == 6 ? 1.15 : 0.92,
          ),
          itemBuilder: (context, index) {
            final shortcut = shortcuts[index];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  ref.read(explorerFilterTypeProvider.notifier).state = shortcut.filterType;
                  context.go(AppRoutes.explorer);
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(shortcut.icon, size: 26),
                      const SizedBox(height: 6),
                      Text(
                        shortcut.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      countsAsync.when(
                        data: (counts) {
                          final count = counts[shortcut.filterType] ?? 0;
                          return Text(
                            '$count',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                        error: (_, __) => Text(
                          'Browse',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        loading: () => SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}

class _RecentLocationTile extends ConsumerWidget {
  const _RecentLocationTile({required this.recent});

  final RecentLocation recent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: Icon(
          recent.isFolder ? Icons.folder_open_rounded : Icons.insert_drive_file,
        ),
        title: Text(
          recent.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          recent.path,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          final pathToOpen =
              recent.isFolder ? recent.path : p.dirname(recent.path);
          ref.read(explorerControllerProvider.notifier).openDirectory(
                pathToOpen,
                recordRecent: false,
              );
          context.go(AppRoutes.explorer);
        },
        trailing: IconButton(
          tooltip: 'Remove recent',
          onPressed: () {
            ref.read(recentsControllerProvider.notifier).removeRecent(
                  recent.path,
                );
          },
          icon: const Icon(Icons.close_rounded),
        ),
      ),
    );
  }
}

class _EmptyRecentsTile extends StatelessWidget {
  const _EmptyRecentsTile();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.history_rounded),
        title: Text('No recent folders yet'),
      ),
    );
  }
}

class _FavoriteLocationTile extends ConsumerWidget {
  const _FavoriteLocationTile({required this.favorite});

  final FavoriteLocation favorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.star_rounded),
        title: Text(
          favorite.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          favorite.path,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          ref.read(explorerControllerProvider.notifier).openDirectory(
                favorite.path,
              );
          context.go(AppRoutes.explorer);
        },
        trailing: IconButton(
          tooltip: 'Remove favorite',
          onPressed: () {
            ref
                .read(favoritesControllerProvider.notifier)
                .removeFavorite(favorite.path);
          },
          icon: const Icon(Icons.close_rounded),
        ),
      ),
    );
  }
}

class _EmptyFavoritesTile extends StatelessWidget {
  const _EmptyFavoritesTile();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.star_border_rounded),
        title: Text('No favorite folders yet'),
      ),
    );
  }
}

class _Shortcut {
  const _Shortcut(this.label, this.icon, this.filterType);

  final String label;
  final IconData icon;
  final FileSystemEntryType filterType;
}
