import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/media/presentation/local_media_actions.dart';
import 'package:file_explorer/features/archive/domain/entities/archive_entry.dart';
import 'package:file_explorer/features/archive/presentation/controllers/archive_viewer_controller.dart';
import 'package:file_explorer/features/archive/presentation/archive_file_preview_screen.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:file_explorer/shared/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ArchiveViewerScreen extends ConsumerWidget {
  const ArchiveViewerScreen({
    required this.archivePath,
    required this.archiveName,
    super.key,
  });

  final String archivePath;
  final String archiveName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(archiveViewerControllerProvider(archivePath));
    final listing = state.listing;

    return BackButtonListener(
      onBackButtonPressed: () async {
        if (ModalRoute.of(context)?.isCurrent != true) {
          return false;
        }
        if (!state.isRoot) {
          await ref
              .read(archiveViewerControllerProvider(archivePath).notifier)
              .openParentDirectory();
        } else {
          Navigator.of(context).maybePop();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (!state.isRoot) {
                ref
                    .read(archiveViewerControllerProvider(archivePath).notifier)
                    .openParentDirectory();
              } else {
                Navigator.of(context).maybePop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                archiveName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (!state.isRoot)
                Text(
                  state.directoryPath,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Open with',
              onPressed: () => _openArchiveWithSystem(context, archivePath),
              icon: const Icon(Icons.open_in_new_rounded),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                ref
                    .read(archiveViewerControllerProvider(archivePath).notifier)
                    .refresh();
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: listing.when(
          loading: () => const AppLoadingIndicator(),
          error: (error, _) => _ArchiveViewerError(
            error: error,
            onRetry: () {
              ref
                  .read(archiveViewerControllerProvider(archivePath).notifier)
                  .refresh();
            },
          ),
          data: (data) => _ArchiveEntryList(
            archivePath: archivePath,
            entries: data.entries,
          ),
        ),
      ),
    );
  }
}

class _ArchiveEntryList extends ConsumerWidget {
  const _ArchiveEntryList({
    required this.archivePath,
    required this.entries,
  });

  final String archivePath;
  final List<ArchiveEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      return const Center(child: Text('This folder is empty'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _ArchiveEntryTile(
          entry: entry,
          onTap: () {
            final controller =
                ref.read(archiveViewerControllerProvider(archivePath).notifier);
            if (entry.isFolder) {
              controller.openDirectory(entry.path);
            } else if (kindForArchivePreview(entry.name) ==
                ArchivePreviewKind.unsupported) {
              showUnsupportedArchiveEntrySheet(
                context: context,
                ref: ref,
                archivePath: archivePath,
                entry: entry,
              );
            } else {
              context.push(
                AppRoutes.archiveFilePreview,
                extra: ArchiveFilePreviewSession(
                  archivePath: archivePath,
                  entry: entry,
                ),
              );
            }
          },
        );
      },
    );
  }
}

class _ArchiveEntryTile extends StatelessWidget {
  const _ArchiveEntryTile({required this.entry, required this.onTap});

  final ArchiveEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final extension = _extensionFor(entry.name);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: entry.isFolder
                    ? Icon(Icons.folder_rounded,
                        size: 40, color: colorScheme.primary)
                    : FileTypeBadge(
                        extension: extension,
                        color: _colorForExtension(context, extension),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildSubtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    if (entry.isFolder) {
      final count = entry.childrenCount;
      if (count != null && count > 0) {
        return '$count items';
      }
      return '';
    }
    return formatBytes(entry.sizeBytes ?? 0);
  }
}

class _ArchiveViewerError extends StatelessWidget {
  const _ArchiveViewerError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_rounded, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Could not read archive',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
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

String _extensionFor(String name) {
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == name.length - 1) {
    return '';
  }
  return name.substring(dotIndex + 1).toLowerCase();
}

Color _colorForExtension(BuildContext context, String extension) {
  final colorScheme = Theme.of(context).colorScheme;
  return switch (extension) {
    'pdf' => FileEntryColors.pdf,
    'doc' || 'docx' || 'odt' || 'rtf' => FileEntryColors.document,
    'xls' || 'xlsx' || 'ods' || 'csv' => FileEntryColors.spreadsheet,
    'ppt' || 'pptx' || 'odp' => FileEntryColors.presentation,
    'txt' || 'md' || 'log' => FileEntryColors.text,
    'json' || 'xml' || 'yaml' || 'yml' => FileEntryColors.data,
    'html' ||
    'css' ||
    'js' ||
    'ts' ||
    'dart' ||
    'kt' ||
    'java' ||
    'py' =>
      FileEntryColors.code,
    'zip' ||
    'tar' ||
    'tgz' ||
    'tbz2' ||
    'txz' ||
    'gz' ||
    'bz2' ||
    'xz' =>
      FileEntryColors.archive,
    'apk' || 'apks' || 'xapk' || 'apkm' || 'aab' => FileEntryColors.app,
    'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' => FileEntryColors.image,
    'mp4' || 'mkv' || 'mov' || 'webm' => FileEntryColors.video,
    'mp3' || 'flac' || 'wav' || 'm4a' => FileEntryColors.audio,
    _ => colorScheme.onSurfaceVariant,
  };
}

Future<void> _openArchiveWithSystem(
    BuildContext context, String archivePath) async {
  try {
    await openLocalFileWithSystem(archivePath);
  } on MissingPluginException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open with is available on Android')),
      );
    }
  } on PlatformException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Could not open file')),
      );
    }
  }
}
