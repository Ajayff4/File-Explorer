import 'dart:math' as math;

import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/app/theme/neumorphic_card.dart';
import 'package:file_explorer/features/analyzer/domain/entities/storage_analysis.dart';
import 'package:file_explorer/features/analyzer/presentation/controllers/analyzer_controller.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

class StorageAnalyzerScreen extends ConsumerStatefulWidget {
  const StorageAnalyzerScreen({required this.rootPath, super.key});

  final String rootPath;

  @override
  ConsumerState<StorageAnalyzerScreen> createState() =>
      _StorageAnalyzerScreenState();
}

class _StorageAnalyzerScreenState extends ConsumerState<StorageAnalyzerScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  void _startScan() {
    if (_started) return;
    _started = true;
    ref.read(analyzerControllerProvider.notifier).scan(widget.rootPath);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyzerControllerProvider);
    final explorerState = ref.watch(explorerControllerProvider);
    final volume = _volumeFor(explorerState, widget.rootPath);

    return Scaffold(
      appBar: AppBar(title: const Text('Storage Analyzer')),
      body: switch (state) {
        AnalyzerState(scanning: true) =>
          _ScanningView(rootPath: widget.rootPath),
        AnalyzerState(error: final error?) => _ErrorView(
            error: error,
            onRetry: () {
              _started = false;
              _startScan();
            },
          ),
        _ => _AnalysisView(analysis: state.analysis, volume: volume),
      },
    );
  }

  StorageVolume? _volumeFor(ExplorerState explorerState, String rootPath) {
    final listingVolume = explorerState.listing.value?.volume;
    if (listingVolume != null && listingVolume.path == rootPath) {
      return listingVolume;
    }
    final volumes = explorerState.volumes.value ?? const <StorageVolume>[];
    for (final volume in volumes) {
      if (volume.path == rootPath) {
        return volume;
      }
    }
    return volumes.isEmpty ? null : volumes.first;
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48),
          const SizedBox(height: 12),
          const Text('Could not analyze storage'),
          const SizedBox(height: 4),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ScanningView extends StatelessWidget {
  const _ScanningView({required this.rootPath});

  final String rootPath;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(strokeWidth: 5),
                  ),
                  Icon(Icons.donut_large_rounded, color: colors.primary, size: 26),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analyzing storage…',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              rootPath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisView extends StatelessWidget {
  const _AnalysisView({required this.analysis, required this.volume});

  final StorageAnalysis? analysis;
  final StorageVolume? volume;

  @override
  Widget build(BuildContext context) {
    final result = analysis;
    if (result == null) {
      return const Center(child: Text('Nothing to show'));
    }

    final total = result.totalBytes;
    final categories = result.categories
        .where((c) => c.bytes > 0)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SummaryCard(analysis: result, volume: volume),
        const SizedBox(height: 12),
        _CategoryCard(categories: categories, total: total),
        const SizedBox(height: 20),
        _SectionTitle(
          title: 'Largest folders',
          subtitle: '${result.folders.length} folders',
        ),
        const SizedBox(height: 8),
        if (result.folders.isEmpty)
          const _EmptyHint(text: 'No folders found')
        else
          ...result.folders.take(10).map(
                (folder) => _FolderRow(
                  folder: folder,
                  total: total,
                ),
              ),
        const SizedBox(height: 20),
        _SectionTitle(
          title: 'Largest files',
          subtitle: '${result.fileCount} files total',
        ),
        const SizedBox(height: 8),
        if (result.files.isEmpty)
          const _EmptyHint(text: 'No files found')
        else
          ...result.files.take(20).map((file) => _FileRow(file: file)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.analysis, required this.volume});

  final StorageAnalysis analysis;
  final StorageVolume? volume;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final summary = volume?.summary;

    return NeumorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.donut_large_rounded, color: colors.primary, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatBytes(analysis.totalBytes),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your files · ${analysis.fileCount} files · '
                        '${analysis.folderCount} folders',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (summary != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                '${volume!.label} · ${formatBytes(summary.usedBytes)} used of '
                '${formatBytes(summary.totalBytes)} · '
                '${formatBytes(summary.freeBytes)} free',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.categories, required this.total});

  final List<CategoryUsage> categories;
  final int total;

  @override
  Widget build(BuildContext context) {
    final segments = <({double fraction, Color color})>[];
    for (final category in categories) {
      segments.add((
        fraction: total == 0 ? 0 : category.bytes / total,
        color: _categoryColor(category.category),
      ));
    }

    return NeumorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Storage by type',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _DonutChart(segments: segments, total: total),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      for (final category in categories)
                        _LegendRow(
                          category: category.category,
                          bytes: category.bytes,
                          total: total,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChart extends StatefulWidget {
  const _DonutChart({required this.segments, required this.total});

  final List<({double fraction, Color color})> segments;
  final int total;

  @override
  State<_DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<_DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 132,
      height: 132,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = Curves.easeOutCubic.transform(_controller.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size.square(132),
                painter: _DonutPainter(
                  segments: widget.segments,
                  progress: progress,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatBytes(widget.total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'total',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.category,
    required this.bytes,
    required this.total,
  });

  final String category;
  final int bytes;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    final percent = total == 0 ? 0.0 : bytes / total * 100;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _categoryLabel(category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatBytes(bytes),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments, required this.progress});

  final List<({double fraction, Color color})> segments;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.15;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final single = segments.length <= 1;
    final gap = single ? 0.0 : 0.04;
    final totalSweep = 2 * math.pi * progress;

    var start = -math.pi / 2;
    for (final segment in segments) {
      final sweep = segment.fraction * totalSweep;
      if (sweep <= 0) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = segment.color
        ..strokeCap = single ? StrokeCap.butt : StrokeCap.round;

      final drawSweep = math.max(0.0, sweep - gap);
      if (drawSweep > 0) {
        canvas.drawArc(rect, start + gap / 2, drawSweep, false, paint);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    if (oldDelegate.progress != progress) return true;
    if (oldDelegate.segments.length != segments.length) return true;
    for (var i = 0; i < segments.length; i++) {
      if (oldDelegate.segments[i].color != segments[i].color ||
          oldDelegate.segments[i].fraction != segments[i].fraction) {
        return true;
      }
    }
    return false;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _FolderRow extends ConsumerWidget {
  const _FolderRow({required this.folder, required this.total});

  final FolderUsage folder;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final fraction = total == 0 ? 0.0 : folder.bytes / total;

    return NeumorphicCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: () {
        ref.read(explorerControllerProvider.notifier).openDirectory(folder.path);
        context.go(AppRoutes.explorer);
      },
      child: ListTile(
        leading: Icon(Icons.folder_rounded, color: colors.primary),
        title: Text(
          p.basename(folder.path),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              folder.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
          ],
        ),
        trailing: Text(
          formatBytes(folder.bytes),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file});

  final LargeFile file;

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          iconForFileSystemEntryType(_typeForCategory(file.category)),
          color: _categoryColor(file.category),
        ),
        title: Text(
          p.basename(file.path),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          file.path,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          formatBytes(file.bytes),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      child: ListTile(
        leading: const Icon(Icons.inbox_rounded),
        title: Text(text),
      ),
    );
  }
}

Color _categoryColor(String category) {
  return switch (category) {
    'image' => FileEntryColors.image,
    'video' => FileEntryColors.video,
    'audio' => FileEntryColors.audio,
    'document' => FileEntryColors.document,
    'archive' => FileEntryColors.archive,
    'app' => FileEntryColors.app,
    _ => const Color(0xFF78909C),
  };
}

String _categoryLabel(String category) {
  return switch (category) {
    'image' => 'Images',
    'video' => 'Videos',
    'audio' => 'Audio',
    'document' => 'Documents',
    'archive' => 'Archives',
    'app' => 'Apps',
    _ => 'Other',
  };
}

FileSystemEntryType _typeForCategory(String category) {
  return switch (category) {
    'image' => FileSystemEntryType.image,
    'video' => FileSystemEntryType.video,
    'audio' => FileSystemEntryType.audio,
    'document' => FileSystemEntryType.document,
    'archive' => FileSystemEntryType.archive,
    'app' => FileSystemEntryType.app,
    _ => FileSystemEntryType.other,
  };
}
