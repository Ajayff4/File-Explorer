import 'package:file_explorer/features/explorer/data/fake/fake_storage_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
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
    final entries = ref.watch(recentEntriesProvider);
    final viewMode = ref.watch(explorerViewModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Internal storage'),
        actions: [
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
          const _BreadcrumbBar(),
          Expanded(
            child: viewMode == ExplorerViewMode.list
                ? _EntryList(entries: entries)
                : _EntryGrid(entries: entries),
          ),
        ],
      ),
    );
  }
}

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            const Icon(Icons.home_rounded, size: 18),
            const SizedBox(width: 8),
            Text(
              'storage',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Icon(Icons.chevron_right_rounded),
            Text(
              'emulated',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Icon(Icons.chevron_right_rounded),
            Text(
              '0',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryList extends StatelessWidget {
  const _EntryList({required this.entries});

  final List<FileSystemEntry> entries;

  @override
  Widget build(BuildContext context) {
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

class _EntryGrid extends StatelessWidget {
  const _EntryGrid({required this.entries});

  final List<FileSystemEntry> entries;

  @override
  Widget build(BuildContext context) {
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
            onTap: () {},
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
  return _formatBytes(entry.sizeBytes ?? 0);
}

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}
