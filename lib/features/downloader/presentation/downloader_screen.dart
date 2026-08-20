import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/downloader/data/repositories/download_engine_provider.dart';
import 'package:file_explorer/features/downloader/domain/entities/download_task.dart';
import 'package:file_explorer/features/downloader/domain/repositories/download_engine.dart';
import 'package:file_explorer/features/downloader/presentation/controllers/downloader_controller.dart';
import 'package:file_explorer/features/downloader/presentation/download_entry_grid.dart';
import 'package:file_explorer/features/downloader/presentation/downloader_visuals.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:file_explorer/app/theme/neumorphic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DownloaderScreen extends ConsumerStatefulWidget {
  const DownloaderScreen({super.key});

  @override
  ConsumerState<DownloaderScreen> createState() => _DownloaderScreenState();
}

class _DownloaderScreenState extends ConsumerState<DownloaderScreen> {
  final _urlController = TextEditingController();
  final _urlFocusNode = FocusNode();
  DownloadMediaType _mediaType = DownloadMediaType.video;
  DownloadQuality _quality = DownloadQuality.auto;
  DownloadAudioFormat _audioFormat = DownloadAudioFormat.original;
  bool _playlist = false;

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _addDownload() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      return;
    }
    ref.read(downloaderControllerProvider.notifier).enqueue(
          url: url,
          mediaType: _mediaType,
          quality: _quality,
          audioFormat: _audioFormat,
          playlist: _playlist,
        );
    _urlController.clear();
    _urlFocusNode.requestFocus();
  }

  Future<void> _pasteUrl() async {
    final clipboard = await Clipboard.getData('text/plain');
    final text = clipboard?.text;
    if (text == null || text.isEmpty) {
      return;
    }
    _urlController.text = text;
    _urlFocusNode.requestFocus();
  }

  Future<void> _showYtDlpUpdateSheet() async {
    final engine = ref.read(downloadEngineProvider);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _YtDlpUpdateSheet(engine: engine),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(downloaderControllerProvider);
    final controller = ref.read(downloaderControllerProvider.notifier);
    final canEnqueue = _urlController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal Downloader'),
        actions: [
          IconButton(
            tooltip: 'yt-dlp update',
            onPressed: _showYtDlpUpdateSheet,
            icon: const Icon(Icons.system_update_alt_rounded),
          ),
          if (state.finishedTasks.isNotEmpty)
            IconButton(
              tooltip: 'Clear finished',
              onPressed: controller.clearFinished,
              icon: const Icon(Icons.done_all_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _UrlEntryCard(
            controller: _urlController,
            focusNode: _urlFocusNode,
            mediaType: _mediaType,
            quality: _quality,
            audioFormat: _audioFormat,
            playlist: _playlist,
            onUrlChanged: (_) => setState(() {}),
            onMediaTypeChanged: (value) => setState(() => _mediaType = value),
            onQualityChanged: (value) => setState(() => _quality = value),
            onAudioFormatChanged: (value) =>
                setState(() => _audioFormat = value),
            onPlaylistChanged: (value) => setState(() => _playlist = value),
            onAdd: canEnqueue ? _addDownload : null,
            onPaste: _pasteUrl,
          ),
          const SizedBox(height: 16),
          _DownloaderSettingsCard(controller: controller, state: state),
          const SizedBox(height: 16),
          _DownloaderSummaryCard(state: state),
          const SizedBox(height: 16),
          if (state.tasks.isEmpty && !state.isLoading)
            const _EmptyDownloaderQueue()
          else ...[
            if (state.activeTasks.isNotEmpty) ...[
              _DownloaderSectionHeader(
                label: 'Active',
                count: state.activeTasks.length,
              ),
              const SizedBox(height: 8),
              for (final task in state.activeTasks)
                _DownloadTaskCard(task: task),
            ],
            if (state.finishedTasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DownloaderSectionHeader(
                label: 'Finished',
                count: state.finishedTasks.length,
              ),
              const SizedBox(height: 8),
              for (final task in state.finishedTasks)
                _DownloadTaskCard(task: task),
            ],
          ],
        ],
      ),
    );
  }
}

class _UrlEntryCard extends StatelessWidget {
  const _UrlEntryCard({
    required this.controller,
    required this.focusNode,
    required this.mediaType,
    required this.quality,
    required this.audioFormat,
    required this.playlist,
    required this.onUrlChanged,
    required this.onMediaTypeChanged,
    required this.onQualityChanged,
    required this.onAudioFormatChanged,
    required this.onPlaylistChanged,
    required this.onAdd,
    required this.onPaste,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final DownloadMediaType mediaType;
  final DownloadQuality quality;
  final DownloadAudioFormat audioFormat;
  final bool playlist;
  final ValueChanged<String> onUrlChanged;
  final ValueChanged<DownloadMediaType> onMediaTypeChanged;
  final ValueChanged<DownloadQuality> onQualityChanged;
  final ValueChanged<DownloadAudioFormat> onAudioFormatChanged;
  final ValueChanged<bool> onPlaylistChanged;
  final VoidCallback? onAdd;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste a media link',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onChanged: onUrlChanged,
                    onSubmitted: (_) => onAdd?.call(),
                    decoration: const InputDecoration(
                      hintText: 'https://youtube.com/...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Paste from clipboard',
                  onPressed: onPaste,
                  icon: const Icon(Icons.content_paste_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final type in DownloadMediaType.values)
                  ChoiceChip(
                    label: Text(type.label),
                    selected: mediaType == type,
                    onSelected: (_) => onMediaTypeChanged(type),
                  ),
                FilterChip(
                  avatar: const Icon(Icons.playlist_play_rounded, size: 18),
                  label: const Text('Playlist'),
                  selected: playlist,
                  onSelected: onPlaylistChanged,
                ),
              ],
            ),
            if (mediaType == DownloadMediaType.audio) ...[
              const SizedBox(height: 8),
              Text(
                'Audio format',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in DownloadAudioFormat.values)
                    ChoiceChip(
                      label: Text(f.label),
                      selected: audioFormat == f,
                      onSelected: (_) => onAudioFormatChanged(f),
                    ),
                ],
              ),
            ],
            if (mediaType == DownloadMediaType.video) ...[
              const SizedBox(height: 8),
              Text(
                'Quality',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final q in DownloadQuality.values)
                    ChoiceChip(
                      label: Text(q.label),
                      selected: quality == q,
                      onSelected: (_) => onQualityChanged(q),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloaderSettingsCard extends ConsumerWidget {
  const _DownloaderSettingsCard({
    required this.controller,
    required this.state,
  });

  final DownloaderController controller;
  final DownloaderState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = state.settings;

    return NeumorphicCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune_rounded),
              title: const Text('Download settings'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.speed_rounded),
              title: const Text('Concurrent downloads'),
              subtitle: Text(
                '${settings.maxConcurrentDownloads} '
                '${settings.maxConcurrentDownloads == 1 ? 'download' : 'downloads'} at once',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Fewer',
                    onPressed: settings.maxConcurrentDownloads <= 1
                        ? null
                        : () => controller.setMaxConcurrentDownloads(
                            settings.maxConcurrentDownloads - 1),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  IconButton(
                    tooltip: 'More',
                    onPressed: settings.maxConcurrentDownloads >= 16
                        ? null
                        : () => controller.setMaxConcurrentDownloads(
                            settings.maxConcurrentDownloads + 1),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.folder_rounded),
              title: const Text('Download folder'),
              subtitle: Text(
                settings.outputDirectory.isEmpty
                    ? 'App-private folder (hidden until moved)'
                    : settings.outputDirectory,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: TextButton(
                onPressed: () => _pickOutputDirectory(context, ref),
                child: const Text('Change'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloaderSummaryCard extends StatelessWidget {
  const _DownloaderSummaryCard({required this.state});

  final DownloaderState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeTask = state.activeTasks.isEmpty
        ? null
        : state.activeTasks.firstWhere(
            (task) => task.status == DownloadTaskStatus.running,
            orElse: () => state.activeTasks.first,
          );

    return NeumorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.downloading_rounded,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeTask == null
                            ? 'Downloads idle'
                            : activeTask.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeTask == null
                            ? 'Waiting for downloads'
                            : _activeTaskLabel(activeTask),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (activeTask != null && activeTask.progress.fraction != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: activeTask.progress.fraction,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                _SummaryStat(
                  label: 'Pending',
                  count: state.pendingCount,
                  color: const Color(0xFF1E88E5),
                ),
                const SizedBox(width: 12),
                _SummaryStat(
                  label: 'Done',
                  count: state.completedCount,
                  color: const Color(0xFF43A047),
                ),
                const SizedBox(width: 12),
                _SummaryStat(
                  label: 'Failed',
                  count: state.failedCount,
                  color: const Color(0xFFE53935),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _activeTaskLabel(DownloadTask task) {
    final progress = task.progress;
    final parts = <String>[
      if (progress.totalBytes != null)
        '${formatBytes(progress.transferredBytes)} of '
            '${formatBytes(progress.totalBytes!)}'
      else if (progress.transferredBytes > 0)
        formatBytes(progress.transferredBytes),
      if (progress.speedBytesPerSecond > 0)
        formatTransferSpeed(progress.speedBytesPerSecond),
    ];
    return parts.isEmpty ? task.status.label : parts.join(' · ');
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloaderSectionHeader extends StatelessWidget {
  const _DownloaderSectionHeader({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadTaskCard extends ConsumerWidget {
  const _DownloadTaskCard({required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(downloaderControllerProvider.notifier);
    final showProgress = task.status == DownloadTaskStatus.running ||
        task.status == DownloadTaskStatus.queued ||
        task.status == DownloadTaskStatus.paused;

    return NeumorphicCard(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorForDownloadStatus(context, task.status)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusIcon(task.status),
                    color: colorForDownloadStatus(context, task.status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitleFor(context, task),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _DownloadTaskActions(task: task, controller: controller),
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: 12),
              _TaskProgressbar(
                  task: task,
                  isActive: task.status == DownloadTaskStatus.running),
            ],
            if (task.failureMessage != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 18, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.failureMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.redAccent,
                          ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Copy error',
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: task.failureMessage!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon:
                        const Icon(Icons.copy_rounded, color: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData statusIcon(DownloadTaskStatus status) {
    return switch (task.status) {
      DownloadTaskStatus.running => Icons.autorenew_rounded,
      DownloadTaskStatus.queued => Icons.hourglass_top_rounded,
      DownloadTaskStatus.completed => Icons.check_circle_rounded,
      DownloadTaskStatus.failed => Icons.error_rounded,
      DownloadTaskStatus.cancelled => Icons.cancel_rounded,
      DownloadTaskStatus.paused => Icons.pause_circle_rounded,
    };
  }

  String _subtitleFor(BuildContext context, DownloadTask task) {
    final progress = task.progress;
    final speed = progress.speedBytesPerSecond;
    final details = <String>[
      task.mediaType.label,
      if (task.mediaType == DownloadMediaType.video) task.quality.label,
      if (task.playlist) 'Playlist',
      if (task.mediaType == DownloadMediaType.audio &&
          task.audioFormat == DownloadAudioFormat.mp3)
        'MP3',
      task.status.label,
    ];
    if (speed > 0) {
      details.add(formatTransferSpeed(speed));
    }
    if (task.isFinished) {
      details.add(formatDownloadTimestamp(task.updatedAt));
    }
    return details.join(' · ');
  }
}

class _TaskProgressbar extends StatelessWidget {
  const _TaskProgressbar({
    required this.task,
    required this.isActive,
  });

  final DownloadTask task;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = task.progress.fraction;
    final totalBytes = task.progress.totalBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        LinearProgressIndicator(
          value: fraction,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          color: scheme.primary,
          backgroundColor: scheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 6),
        Text(
          totalBytes != null
              ? '${formatBytes(task.progress.transferredBytes)} of ${formatBytes(totalBytes)}'
              : task.status == DownloadTaskStatus.running
                  ? 'Downloading…'
                  : task.status.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _DownloadTaskActions extends ConsumerWidget {
  const _DownloadTaskActions({
    required this.task,
    required this.controller,
  });

  final DownloadTask task;
  final DownloaderController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (task.status == DownloadTaskStatus.completed) {
      return _CompletedTaskMenu(task: task);
    }
    final actions = <Widget>[
      if (task.canPause)
        IconButton(
          tooltip: 'Pause',
          onPressed: () => controller.pause(task.id),
          icon: const Icon(Icons.pause_circle_outline_rounded),
        ),
      if (task.canResume)
        IconButton(
          tooltip: 'Resume',
          onPressed: () => controller.resume(task.id),
          icon: const Icon(Icons.play_circle_outline_rounded),
        ),
      if (task.canRetry)
        IconButton(
          tooltip: 'Retry',
          onPressed: () => controller.retry(task.id),
          icon: const Icon(Icons.refresh_rounded),
        ),
      if (task.canCancel)
        IconButton(
          tooltip: 'Cancel',
          onPressed: () => controller.cancel(task.id),
          icon: const Icon(Icons.close_rounded),
        ),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...actions,
        _CopyUrlMenu(task: task),
      ],
    );
  }
}

class _CopyUrlMenu extends StatelessWidget {
  const _CopyUrlMenu({required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      tooltip: 'More actions',
      icon: const Icon(Icons.more_vert_rounded),
      padding: EdgeInsets.zero,
      iconSize: 22,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      color: Theme.of(context).colorScheme.surfaceContainer,
      onSelected: (callback) => callback(),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: () => _copyTaskUrl(context, task),
          height: 46,
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.link_rounded,
                  size: 19,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text('Copy URL', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

void _copyTaskUrl(BuildContext context, DownloadTask task) {
  Clipboard.setData(ClipboardData(text: task.url));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('URL copied to clipboard'),
      duration: Duration(seconds: 2),
    ),
  );
}

class _CompletedTaskMenu extends ConsumerWidget {
  const _CompletedTaskMenu({required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_CompletedAction>(
      tooltip: 'More actions',
      icon: const Icon(Icons.more_vert_rounded),
      padding: EdgeInsets.zero,
      iconSize: 22,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      color: Theme.of(context).colorScheme.surfaceContainer,
      onSelected: (action) {
        switch (action) {
          case _CompletedAction.move:
            final path = task.savedPath;
            if (path.isNotEmpty) {
              ref.read(transferControllerProvider.notifier).queueOperation(
                    operation: TransferOperation.move,
                    sourcePaths: [path],
                    displayName: task.displayName,
                  );
            }
          case _CompletedAction.openFolder:
            context.push(AppRoutes.downloaderBrowse,
                extra: task.outputDirectory);
          case _CompletedAction.browse:
            context.push(AppRoutes.downloaderBrowse,
                extra: task.outputDirectory);
          case _CompletedAction.copyUrl:
            _copyTaskUrl(context, task);
        }
      },
      itemBuilder: (context) => [
        if (task.savedPath.isNotEmpty)
          _menuItem(
            context,
            value: _CompletedAction.move,
            icon: Icons.drive_file_move_outlined,
            label: 'Move to',
          ),
        _menuItem(
          context,
          value: _CompletedAction.openFolder,
          icon: Icons.folder_open_rounded,
          label: 'Open folder',
        ),
        _menuItem(
          context,
          value: _CompletedAction.browse,
          icon: Icons.manage_search_rounded,
          label: 'Browse',
        ),
        _menuItem(
          context,
          value: _CompletedAction.copyUrl,
          icon: Icons.link_rounded,
          label: 'Copy URL',
        ),
      ],
    );
  }

  PopupMenuItem<_CompletedAction> _menuItem(
    BuildContext context, {
    required _CompletedAction value,
    required IconData icon,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuItem(
      value: value,
      height: 46,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: scheme.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

enum _CompletedAction { move, openFolder, browse, copyUrl }

class _EmptyDownloaderQueue extends StatelessWidget {
  const _EmptyDownloaderQueue();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.download_rounded,
              size: 36,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No downloads yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Paste a YouTube, Instagram, Twitter, or other video link above.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

Future<void> _pickOutputDirectory(BuildContext context, WidgetRef ref) async {
  final repository = ref.read(storageRepositoryProvider);
  var currentPath =
      ref.read(downloaderControllerProvider).settings.outputDirectory;
  if (currentPath.isEmpty) {
    final volumes = await repository.getStorageVolumes();
    currentPath = volumes.isEmpty ? '/' : volumes.first.path;
  }

  if (!context.mounted) {
    return;
  }

  final selected = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: _FolderPickerSheet(
          repository: repository,
          startPath: currentPath,
          onSelected: (path) => Navigator.of(sheetContext).pop(path),
        ),
      );
    },
  );

  if (selected != null && selected.isNotEmpty && context.mounted) {
    ref
        .read(downloaderControllerProvider.notifier)
        .setOutputDirectory(selected);
  }
}

class _FolderPickerSheet extends StatefulWidget {
  const _FolderPickerSheet({
    required this.repository,
    required this.startPath,
    required this.onSelected,
  });

  final StorageRepository repository;
  final String startPath;
  final ValueChanged<String> onSelected;

  @override
  State<_FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends State<_FolderPickerSheet> {
  late String _currentPath;
  List<FileSystemEntry> _folders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.startPath;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _folders = [];
    });
    try {
      final listing = await widget.repository.listDirectory(_currentPath);
      if (!mounted) {
        return;
      }
      setState(() {
        _folders = listing.entries.where((entry) => entry.isFolder).toList()
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _createFolder() async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String input = '';
        return AlertDialog(
          title: const Text('New folder'),
          content: TextField(
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Folder name',
              hintText: 'e.g. My Downloads',
            ),
            onChanged: (value) => input = value,
            onSubmitted: (value) =>
                Navigator.of(dialogContext).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(input.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty || !mounted) {
      return;
    }

    final path = _currentPath.endsWith('/')
        ? '$_currentPath$name'
        : '$_currentPath/$name';
    final created = await widget.repository.createFolder(path);
    if (!mounted) {
      return;
    }
    if (created) {
      setState(() {
        _currentPath = path;
      });
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create that folder')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Up',
                  onPressed: _currentPath == _parent(_currentPath)
                      ? null
                      : () {
                          setState(() {
                            _currentPath = _parent(_currentPath);
                          });
                          _load();
                        },
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                IconButton(
                  tooltip: 'Create folder',
                  onPressed: () => _createFolder(),
                  icon: const Icon(Icons.create_new_folder_rounded),
                ),
                Expanded(
                  child: Text(
                    _currentPath,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onSelected(_currentPath),
                  child: const Text('Use folder'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _folders.isEmpty
                    ? const Center(child: Text('No sub-folders'))
                    : DownloadEntryGrid(
                        entries: _folders,
                        onOpen: (folder) {
                          setState(() {
                            _currentPath = folder.path;
                          });
                          _load();
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _parent(String path) {
    if (path == '/' || path.isEmpty) {
      return '/';
    }
    final index = path.lastIndexOf('/');
    return index <= 0 ? '/' : path.substring(0, index);
  }
}

class _YtDlpUpdateSheet extends ConsumerStatefulWidget {
  const _YtDlpUpdateSheet({required this.engine});

  final DownloadEngine engine;

  @override
  ConsumerState<_YtDlpUpdateSheet> createState() => _YtDlpUpdateSheetState();
}

class _YtDlpUpdateSheetState extends ConsumerState<_YtDlpUpdateSheet> {
  YtDlpUpdateInfo? _info;
  YtDlpApplyResult? _applyResult;
  bool _checking = true;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _info = null;
      _applyResult = null;
    });
    final info = await widget.engine.checkUpdate();
    if (!mounted) {
      return;
    }
    setState(() {
      _info = info;
      _checking = false;
    });
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    final result = await widget.engine.applyUpdate();
    if (!mounted) {
      return;
    }
    setState(() {
      _applyResult = result;
      _applying = false;
      if (result.applied && _info != null) {
        _info = YtDlpUpdateInfo(
          currentVersion: result.version,
          latestVersion: _info!.latestVersion,
          updateAvailable: false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.system_update_alt_rounded,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'yt-dlp engine',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatus(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _checking || _applying ? null : _apply,
                icon: _applying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(_applying ? 'Updating…' : 'Check & update'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus() {
    final theme = Theme.of(context);
    if (_checking) {
      return const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Checking for updates…'),
        ],
      );
    }

    final info = _info;
    if (info == null) {
      return Text('Update check failed', style: theme.textTheme.bodyMedium);
    }

    final applyResult = _applyResult;
    final statusColor = applyResult != null
        ? (applyResult.applied ? Colors.green : theme.colorScheme.error)
        : theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(label: 'Installed', value: info.currentVersion),
        const SizedBox(height: 8),
        _InfoRow(label: 'Latest', value: info.latestVersion),
        if (info.hasError) ...[
          const SizedBox(height: 8),
          Text(
            info.error!,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ],
        if (applyResult != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                applyResult.applied
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                size: 20,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  applyResult.applied
                      ? 'Updated to ${applyResult.version}'
                      : (applyResult.message?.isNotEmpty == true
                          ? applyResult.message!
                          : 'Update could not be applied'),
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
        ] else if (info.updateAvailable) ...[
          const SizedBox(height: 12),
          Text(
            'An update is available.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Text('You are up to date.', style: theme.textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'Unknown' : value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
