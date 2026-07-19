import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('queues destination-based operations until a destination is provided',
      () {
    final controller = TransferController();

    final task = controller.queueOperation(
      operation: TransferOperation.copy,
      sourcePaths: const ['/storage/emulated/0/file.txt'],
      displayName: 'file.txt',
      totalBytes: 100,
    );

    expect(task.status, TransferTaskStatus.awaitingDestination);
    expect(controller.debugState.pendingCount, 1);

    controller.setDestination(
      taskId: task.id,
      destinationPath: '/storage/emulated/0/Download',
    );

    final updatedTask = controller.debugState.tasks.single;
    expect(updatedTask.status, TransferTaskStatus.queued);
    expect(updatedTask.destinationPath, '/storage/emulated/0/Download');
  });

  test('tracks progress and completion', () {
    final controller = TransferController();
    final task = controller.queueOperation(
      operation: TransferOperation.delete,
      sourcePaths: const ['/storage/emulated/0/file.txt'],
      displayName: 'file.txt',
      totalBytes: 100,
    );

    expect(task.status, TransferTaskStatus.queued);

    controller.updateProgress(taskId: task.id, transferredBytes: 40);

    final runningTask = controller.debugState.tasks.single;
    expect(runningTask.status, TransferTaskStatus.running);
    expect(runningTask.progress.fraction, 0.4);

    controller.complete(task.id);

    final completedTask = controller.debugState.tasks.single;
    expect(completedTask.status, TransferTaskStatus.completed);
    expect(controller.debugState.finishedCount, 1);
  });

  test('cancels pending work and clears finished tasks', () {
    final controller = TransferController();
    final task = controller.queueOperation(
      operation: TransferOperation.delete,
      sourcePaths: const ['/storage/emulated/0/file.txt'],
      displayName: 'file.txt',
    );

    controller.cancel(task.id);

    expect(
      controller.debugState.tasks.single.status,
      TransferTaskStatus.cancelled,
    );

    controller.clearFinished();

    expect(controller.debugState.tasks, isEmpty);
  });

  test('retries failed tasks without keeping the old failure message', () {
    final controller = TransferController();
    final task = controller.queueOperation(
      operation: TransferOperation.delete,
      sourcePaths: const ['/storage/emulated/0/file.txt'],
      displayName: 'file.txt',
    );

    controller.fail(taskId: task.id, message: 'Permission denied');
    expect(
        controller.debugState.tasks.single.failureMessage, 'Permission denied');

    controller.retry(task.id);

    final retriedTask = controller.debugState.tasks.single;
    expect(retriedTask.status, TransferTaskStatus.queued);
    expect(retriedTask.failureMessage, isNull);
  });
}
