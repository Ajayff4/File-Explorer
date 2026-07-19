import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(listing.valueOrNull?.volume?.label ?? 'Files'),
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
          if (listing.valueOrNull?.generatedFromSampleData ?? false)
            const _SampleDataBanner(),
          Expanded(
            child: listing.when(
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
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
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
            leading: Icon(_iconFor(entry.type)),
            title:
                Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(_entryDetail(entry)),
            onTap: entry.isFolder
                ? () {
                    // Folder navigation is routed through the controller so
                    // permission and provider errors stay centralized.
                    ref
                        .read(explorerControllerProvider.notifier)
                        .openDirectory(entry.path);
                  }
                : null,
            trailing: IconButton(
              tooltip: 'More',
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded),
            ),
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
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: entry.isFolder
                ? () {
                    ref
                        .read(explorerControllerProvider.notifier)
                        .openDirectory(entry.path);
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_iconFor(entry.type), size: 36),
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
                    _entryDetail(entry),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
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

IconData _iconFor(FileSystemEntryType type) {
  return switch (type) {
    FileSystemEntryType.folder => Icons.folder_rounded,
    FileSystemEntryType.image => Icons.image_rounded,
    FileSystemEntryType.video => Icons.movie_rounded,
    FileSystemEntryType.audio => Icons.music_note_rounded,
    FileSystemEntryType.document => Icons.description_rounded,
    FileSystemEntryType.archive => Icons.inventory_2_rounded,
    FileSystemEntryType.app => Icons.apps_rounded,
    FileSystemEntryType.other => Icons.insert_drive_file_rounded,
  };
}

String _entryDetail(FileSystemEntry entry) {
  if (entry.isFolder) {
    return '${entry.childrenCount ?? 0} items';
  }
  return formatBytes(entry.sizeBytes ?? 0);
}
