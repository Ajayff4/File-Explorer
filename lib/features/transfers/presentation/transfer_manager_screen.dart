import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:file_explorer/features/transfers/presentation/transfer_visuals.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
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
        title: const Text('Transfers'),
        actions: [
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
          const SizedBox(height: 12),
          if (state.tasks.isEmpty)
            const _EmptyTransferQueue()
          else ...[
            if (pendingTasks.isNotEmpty) ...[
              _TransferSectionHeader(
                label: 'Pending',
                count: pendingTasks.length,
              ),
              const SizedBox(height: 8),
              for (final task in pendingTasks)
                _TransferTaskTile(task: task, controller: controller),
            ],
            if (finishedTasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              _TransferSectionHeader(
                label: 'Finished',
                count: finishedTasks.length,
              ),
              const SizedBox(height: 8),
              for (final task in finishedTasks)
                _TransferTaskTile(task: task, controller: controller),
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
    final activeTask = state.activeTask;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.sync_alt_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeTask == null
                        ? 'Transfer queue'
                        : activeTask.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.pendingCount} pending - ${state.finishedCount} finished - ${state.failedCount} failed',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '$label ($count)',
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _TransferTaskTile extends StatelessWidget {
  const _TransferTaskTile({
    required this.task,
    required this.controller,
  });

  final TransferTask task;
  final TransferController controller;

  @override
  Widget build(BuildContext context) {
    final statusColor = colorForTransferStatus(context, task.status);

    return Card(
      child: ListTile(
        leading: Icon(
          iconForTransferOperation(task.operation),
          color: statusColor,
        ),
        title: Text(
          task.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_subtitleFor(task)),
              if (task.failureMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  task.failureMessage!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 8),
              LinearProgressIndicator(value: task.progress.fraction),
            ],
          ),
        ),
        trailing: _TransferTaskActions(task: task, controller: controller),
      ),
    );
  }

  String _subtitleFor(TransferTask task) {
    final progress = task.progress;
    final totalBytes = progress.totalBytes;
    final progressLabel = totalBytes == null
        ? task.status.label
        : '${formatBytes(progress.transferredBytes)} of ${formatBytes(totalBytes)}';
    final destination = task.destinationPath;
    if (destination == null || destination.isEmpty) {
      return '${task.operation.label} - $progressLabel';
    }
    return '${task.operation.label} to $destination - $progressLabel';
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
    return const SizedBox.square(dimension: 48);
  }
}

class _EmptyTransferQueue extends StatelessWidget {
  const _EmptyTransferQueue();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No transfer tasks yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
