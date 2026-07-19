import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/data/fake/fake_storage_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(storageSummaryProvider);
    final recentEntries = ref.watch(recentEntriesProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('File Explorer'),
          actions: [
            IconButton(
              tooltip: 'Search',
              onPressed: () {},
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
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Recent',
                actionLabel: 'Browse',
                onPressed: () => context.go(AppRoutes.explorer),
              ),
              const SizedBox(height: 8),
              ...recentEntries.map((entry) => _RecentEntryTile(entry: entry)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StoragePanel extends StatelessWidget {
  const _StoragePanel({required this.summary});

  final StorageSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
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
                    summary.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  _formatBytes(summary.freeBytes),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: summary.usedFraction,
                minHeight: 10,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${_formatBytes(summary.usedBytes)} used of ${_formatBytes(summary.totalBytes)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid();

  @override
  Widget build(BuildContext context) {
    const shortcuts = [
      _Shortcut('Images', Icons.image_outlined, '428 files'),
      _Shortcut('Video', Icons.movie_outlined, '62 files'),
      _Shortcut('Audio', Icons.music_note_outlined, '311 files'),
      _Shortcut('Apps', Icons.apps_outlined, '47 apps'),
      _Shortcut('Archives', Icons.inventory_2_outlined, '12 files'),
      _Shortcut('Network', Icons.wifi_tethering_outlined, 'LAN/FTP'),
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
            childAspectRatio: columns == 6 ? 1.15 : 1,
          ),
          itemBuilder: (context, index) {
            final shortcut = shortcuts[index];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.go(AppRoutes.explorer),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(shortcut.icon, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        shortcut.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shortcut.detail,
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

class _RecentEntryTile extends StatelessWidget {
  const _RecentEntryTile({required this.entry});

  final FileSystemEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(_iconFor(entry.type)),
        title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          entry.path,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          entry.isFolder
              ? '${entry.childrenCount ?? 0} items'
              : _formatBytes(entry.sizeBytes ?? 0),
        ),
      ),
    );
  }
}

class _Shortcut {
  const _Shortcut(this.label, this.icon, this.detail);

  final String label;
  final IconData icon;
  final String detail;
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
