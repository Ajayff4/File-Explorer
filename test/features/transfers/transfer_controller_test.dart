import 'dart:async';

import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_executor.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('waits for destination before starting copy', () async {
    final executor = _HoldingTransferExecutor();
    final controller = TransferController(executor);

    final task = controller.queueOperation(
      operation: TransferOperation.copy,
      sourcePaths: const ['/storage/emulated/0/file.txt'],
      displayName: 'file.txt',
      totalBytes: 100,
    );

    expect(task.status, TransferTaskStatus.awaitingDestination);
    expect(controller.state.awaitingDestinationTask?.id, task.id);
    expect(controller.state.pendingCount, 1);
    expect(executor.startedTaskIds, isEmpty);

    controller.setDestination(
      taskId: task.id,
      destinationPath: '/storage/emulated/0/Download',
    );
    await _pumpEventQueue();

    final runningTask = controller.state.tasks.single;
    expect(runningTask.status, TransferTaskStatus.running);
    expect(runningTask.destinationPath, '/storage/emulated/0/Download');
    expect(executor.startedTaskIds, [task.id]);
  });

  test('tracks progress and completion from executor', () async {
    final executor = _ProgressTransferExecutor();
    final controller = TransferController(executor);

    final task = controller.queueOperation(
      operation: TransferOperation.delete,
      sourcePaths: const ['/storage/emulated/0/file.txt'],
      displayName: 'file.txt',
      totalBytes: 100,
    );

    await _pumpEventQueue();

    final completedTask = controller.state.tasks.single;
    expect(completedTask.id, task.id);
    expect(completedTask.status, TransferTaskStatus.completed);
    expect(completedTask.progress.fraction, 1);
    expect(controller.state.finishedCount, 1);
  });

  test('cancels pending work and clear finished removes it', () async {
    final executor = _HoldingTransferExecutor();
    final controller = TransferController(executor);
    final task = controller.queueOperation(
      operation: TransferOperation.delete,
      sourcePaths: const ['/storage/emulated/0/file.txt'],
      displayName: 'file.txt',
    );

    controller.cancel(task.id);
    executor.complete();
    await _pumpEventQueue();

    expect(
      controller.state.tasks.single.status,
      TransferTaskStatus.cancelled,
    );

    controller.clearFinished();

    expect(controller.state.tasks, isEmpty);
  });

  test('retries failed tasks without keeping old failure message', () async {
    final executor = _FailingTransferExecutor();
    final controller = TransferController(executor);
    final task = controller.queueOperation(
      operation: TransferOperation.delete,
      sourcePaths: const ['/storage/emulated/0/file.txt'],
      displayName: 'file.txt',
    );

    await _pumpEventQueue();
    expect(controller.state.tasks.single.status, TransferTaskStatus.failed);
    expect(controller.state.tasks.single.failureMessage, contains('Nope'));

    executor.shouldFail = false;
    controller.retry(task.id);
    await _pumpEventQueue();

    final retriedTask = controller.state.tasks.single;
    expect(retriedTask.status, TransferTaskStatus.completed);
    expect(retriedTask.failureMessage, isNull);
  });

  test('resolves destination conflict with selected policy', () async {
    final executor = _ConflictTransferExecutor();
    final controller = TransferController(executor);
    final task = controller.queueOperation(
      operation: TransferOperation.rename,
      sourcePaths: const ['/storage/emulated/0/file.txt'],
      displayName: 'file.txt',
      destinationPath: '/storage/emulated/0/existing.txt',
    );

    await _pumpEventQueue();

    final failedTask = controller.state.tasks.single;
    expect(failedTask.status, TransferTaskStatus.failed);
    expect(failedTask.failureCode, TransferFailureCode.destinationExists);

    controller.resolveConflict(
      taskId: task.id,
      policy: ConflictPolicy.overwrite,
    );
    await _pumpEventQueue();

    final resolvedTask = controller.state.tasks.single;
    expect(resolvedTask.status, TransferTaskStatus.completed);
    expect(resolvedTask.conflictPolicy, ConflictPolicy.overwrite);
    expect(resolvedTask.failureMessage, isNull);
    expect(resolvedTask.failureCode, isNull);
    expect(executor.policies, [ConflictPolicy.ask, ConflictPolicy.overwrite]);
  });
}

Future<void> _pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _HoldingTransferExecutor implements TransferExecutor {
  final startedTaskIds = <String>[];
  final _completer = Completer<void>();

  @override
  Future<void> execute(
    TransferTask task, {
    required TransferProgressCallback onProgress,
  }) {
    startedTaskIds.add(task.id);
    return _completer.future;
  }

  void complete() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }
}

class _ProgressTransferExecutor implements TransferExecutor {
  @override
  Future<void> execute(
    TransferTask task, {
    required TransferProgressCallback onProgress,
  }) async {
    onProgress(
      TransferProgress(
        transferredBytes: 40,
        totalBytes: task.progress.totalBytes,
        currentItemPath: task.sourcePaths.first,
      ),
    );
    onProgress(
      TransferProgress(
        transferredBytes: task.progress.totalBytes ?? 1,
        totalBytes: task.progress.totalBytes ?? 1,
        currentItemPath: task.sourcePaths.first,
      ),
    );
  }
}

class _FailingTransferExecutor implements TransferExecutor {
  bool shouldFail = true;

  @override
  Future<void> execute(
    TransferTask task, {
    required TransferProgressCallback onProgress,
  }) async {
    if (shouldFail) {
      throw Exception('Nope');
    }
  }
}

class _ConflictTransferExecutor implements TransferExecutor {
  final policies = <ConflictPolicy>[];

  @override
  Future<void> execute(
    TransferTask task, {
    required TransferProgressCallback onProgress,
  }) async {
    policies.add(task.conflictPolicy);
    if (task.conflictPolicy == ConflictPolicy.ask) {
      throw const TransferExecutionException(
        code: TransferFailureCode.destinationExists,
        message: 'Destination already exists',
        path: '/storage/emulated/0/existing.txt',
      );
    }
  }
}
