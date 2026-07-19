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
    expect(controller.debugState.pendingCount, 1);
    expect(executor.startedTaskIds, isEmpty);

    controller.setDestination(
      taskId: task.id,
      destinationPath: '/storage/emulated/0/Download',
    );
    await _pumpEventQueue();

    final runningTask = controller.debugState.tasks.single;
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

    final completedTask = controller.debugState.tasks.single;
    expect(completedTask.id, task.id);
    expect(completedTask.status, TransferTaskStatus.completed);
    expect(completedTask.progress.fraction, 1);
    expect(controller.debugState.finishedCount, 1);
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
      controller.debugState.tasks.single.status,
      TransferTaskStatus.cancelled,
    );

    controller.clearFinished();

    expect(controller.debugState.tasks, isEmpty);
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
    expect(
        controller.debugState.tasks.single.status, TransferTaskStatus.failed);
    expect(controller.debugState.tasks.single.failureMessage, contains('Nope'));

    executor.shouldFail = false;
    controller.retry(task.id);
    await _pumpEventQueue();

    final retriedTask = controller.debugState.tasks.single;
    expect(retriedTask.status, TransferTaskStatus.completed);
    expect(retriedTask.failureMessage, isNull);
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
