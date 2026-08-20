import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:file_explorer/features/transfers/presentation/transfer_visuals.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:file_explorer/app/theme/neumorphic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransferManagerScreen extends ConsumerWidget {
  const TransferManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferControllerProvider);
    final controller = ref.read(transferControllerProvider.notifier);
    final pendingTasks = state.tasks.where((task) => !task.isFinished).toList();
    final finishedTasks = state.tasks.where((task) => task.isFinished).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Station'),
        actions: [
          if (pendingTasks.any((task) => task.canCancel))
            IconButton(
              tooltip: 'Cancel all active',
              onPressed: controller.cancelAllPending,
              icon: const Icon(Icons.stop_circle_outlined),
            ),
          IconButton(
            tooltip: 'Clear finished',
            onPressed: finishedTasks.isEmpty ? null : controller.clearFinished,
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TransferSummaryCard(state: state),
          const SizedBox(height: 16),
          if (state.tasks.isEmpty)
            const _EmptyTransferQueue()
          else ...[
            if (pendingTasks.isNotEmpty) ...[
              _TransferSectionHeader(
                label: 'Active',
                count: pendingTasks.length,
              ),
              const SizedBox(height: 8),
              for (final task in pendingTasks)
                _TransferTaskCard(task: task, controller: controller),
            ],
            if (finishedTasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              _TransferSectionHeader(
                label: 'Finished',
                count: finishedTasks.length,
              ),
              const SizedBox(height: 8),
              for (final task in finishedTasks)
                _TransferTaskCard(task: task, controller: controller),
            ],
          ],
        ],
      ),
    );
  }
}

class _TransferSummaryCard extends StatelessWidget {
  const _TransferSummaryCard({required this.state});

  final TransferState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeTask = state.activeTask;

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
                    Icons.sync_alt_rounded,
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
                            ? 'Queue idle'
                            : activeTask.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeTask == null
                            ? 'Waiting for transfers'
                            : _progressLabel(context, activeTask),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (activeTask != null) ...[
              const SizedBox(height: 14),
              _ActiveProgressbar(task: activeTask),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                _SummaryStat(
                  label: 'Pending',
                  count: state.pendingCount,
                  color: colorForTransferStatus(
                    context,
                    TransferTaskStatus.queued,
                  ),
                ),
                const SizedBox(width: 12),
                _SummaryStat(
                  label: 'Finished',
                  count: state.finishedCount,
                  color: colorForTransferStatus(
                    context,
                    TransferTaskStatus.completed,
                  ),
                ),
                const SizedBox(width: 12),
                _SummaryStat(
                  label: 'Failed',
                  count: state.failedCount,
                  color: colorForTransferStatus(
                    context,
                    TransferTaskStatus.failed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _progressLabel(BuildContext context, TransferTask task) {
    final fraction = task.progress.fraction;
    if (fraction != null) {
      return '${_percent(fraction)} · ${_bytesLabel(task)}';
    }
    return task.status.label;
  }
}

class _ActiveProgressbar extends StatelessWidget {
  const _ActiveProgressbar({required this.task});

  final TransferTask task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = task.progress.fraction;
    final isIndeterminate = fraction == null;

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
          isIndeterminate
              ? _bytesLabel(task)
              : '${_percent(fraction)}  ·  ${_bytesLabel(task)}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
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

class _TransferSectionHeader extends StatelessWidget {
  const _TransferSectionHeader({
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

class _TransferTaskCard extends StatelessWidget {
  const _TransferTaskCard({
    required this.task,
    required this.controller,
  });

  final TransferTask task;
  final TransferController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showProgress = task.status == TransferTaskStatus.running ||
        task.status == TransferTaskStatus.queued;

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
                    color: colorForTransferOperation(
                      task.operation,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconForTransferOperation(task.operation),
                    color: colorForTransferOperation(task.operation),
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
                        _subtitleFor(task),
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
                _TransferStatusBadge(status: task.status),
                _TransferTaskActions(task: task, controller: controller),
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: 12),
              _TaskProgressbar(task: task),
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
                ],
              ),
            ],
            if (task.failureCode == TransferFailureCode.destinationExists) ...[
              const SizedBox(height: 12),
              _ConflictActions(task: task, controller: controller),
            ],
          ],
        ),
      ),
    );
  }

  String _subtitleFor(TransferTask task) {
    final progress = task.progress;
    final totalBytes = progress.totalBytes;
    final destination = task.destinationPath;
    final operationLabel = task.operation.label;
    if (destination == null || destination.isEmpty) {
      if (totalBytes != null) {
        return '${task.status.label} · '
            '${formatBytes(progress.transferredBytes)} of ${formatBytes(totalBytes)}';
      }
      return '${task.operation.label} · ${task.status.label}';
    }
    final suffix = totalBytes != null
        ? '${formatBytes(progress.transferredBytes)} of ${formatBytes(totalBytes)}'
        : task.status.label;
    return '$operationLabel to $destination · $suffix';
  }
}

class _TaskProgressbar extends StatelessWidget {
  const _TaskProgressbar({required this.task});

  final TransferTask task;

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
              : task.status.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _TransferStatusBadge extends StatelessWidget {
  const _TransferStatusBadge({required this.status});

  final TransferTaskStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, label) = switch (status) {
      TransferTaskStatus.running => (
          Icons.autorenew_rounded,
          scheme.primary,
          'Running'
        ),
      TransferTaskStatus.queued => (
          Icons.hourglass_top_rounded,
          colorForTransferStatus(context, TransferTaskStatus.queued),
          'Queued'
        ),
      TransferTaskStatus.awaitingDestination => (
          Icons.move_to_inbox_rounded,
          colorForTransferStatus(
              context, TransferTaskStatus.awaitingDestination),
          'Needs destination'
        ),
      TransferTaskStatus.completed => (
          Icons.check_circle_rounded,
          colorForTransferStatus(context, TransferTaskStatus.completed),
          'Done'
        ),
      TransferTaskStatus.failed => (
          Icons.error_rounded,
          colorForTransferStatus(context, TransferTaskStatus.failed),
          'Failed'
        ),
      TransferTaskStatus.cancelled => (
          Icons.cancel_rounded,
          scheme.outline,
          'Cancelled'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _TransferTaskActions extends StatelessWidget {
  const _TransferTaskActions({
    required this.task,
    required this.controller,
  });

  final TransferTask task;
  final TransferController controller;

  @override
  Widget build(BuildContext context) {
    if (task.failureCode == TransferFailureCode.destinationExists) {
      return const SizedBox.square(dimension: 0);
    }
    if (task.canRetry) {
      return IconButton(
        tooltip: 'Retry',
        onPressed: () => controller.retry(task.id),
        icon: const Icon(Icons.refresh_rounded),
      );
    }
    if (task.canCancel) {
      return IconButton(
        tooltip: 'Cancel',
        onPressed: () => controller.cancel(task.id),
        icon: const Icon(Icons.close_rounded),
      );
    }
    return const SizedBox.square(dimension: 40);
  }
}

class _ConflictActions extends StatelessWidget {
  const _ConflictActions({
    required this.task,
    required this.controller,
  });

  final TransferTask task;
  final TransferController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget button(IconData icon, String label, ConflictPolicy policy) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => controller.resolveConflict(
          taskId: task.id,
          policy: policy,
        ),
        icon: Icon(icon, size: 16),
        label: Text(label),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        button(Icons.visibility_off_outlined, 'Skip', ConflictPolicy.skip),
        button(Icons.find_replace_rounded, 'Replace', ConflictPolicy.overwrite),
        button(Icons.copy_rounded, 'Keep both', ConflictPolicy.rename),
      ],
    );
  }
}

class _EmptyTransferQueue extends StatelessWidget {
  const _EmptyTransferQueue();

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
              Icons.inbox_rounded,
              size: 36,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transfers yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Copy, move, or delete files to start a transfer.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

String _bytesLabel(TransferTask task) {
  final total = task.progress.totalBytes;
  if (total == null) {
    return formatBytes(task.progress.transferredBytes);
  }
  return '${formatBytes(task.progress.transferredBytes)} of ${formatBytes(total)}';
}

String _percent(double fraction) {
  return '${(fraction * 100).round()}%';
}
