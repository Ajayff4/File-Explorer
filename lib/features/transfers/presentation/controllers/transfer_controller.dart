import 'dart:async';

import 'package:file_explorer/features/transfers/data/repositories/transfer_executor_provider.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_executor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transferControllerProvider =
    StateNotifierProvider<TransferController, TransferState>((ref) {
  return TransferController(ref.read(transferExecutorProvider));
});

class TransferState {
  const TransferState({
    this.tasks = const [],
  });

  final List<TransferTask> tasks;

  TransferTask? get activeTask {
    for (final task in tasks) {
      if (task.isActive) {
        return task;
      }
    }
    return null;
  }

  TransferTask? get awaitingDestinationTask {
    for (final task in tasks) {
      if (task.status == TransferTaskStatus.awaitingDestination) {
        return task;
      }
    }
    return null;
  }

  int get pendingCount {
    return tasks
        .where(
          (task) =>
              task.status == TransferTaskStatus.awaitingDestination ||
              task.status == TransferTaskStatus.queued ||
              task.status == TransferTaskStatus.running,
        )
        .length;
  }

  int get failedCount {
    return tasks
        .where((task) => task.status == TransferTaskStatus.failed)
        .length;
  }

  int get finishedCount {
    return tasks.where((task) => task.isFinished).length;
  }

  TransferState copyWith({
    List<TransferTask>? tasks,
  }) {
    return TransferState(
      tasks: tasks ?? this.tasks,
    );
  }
}

class TransferController extends StateNotifier<TransferState> {
  TransferController(this._executor) : super(const TransferState());

  final TransferExecutor _executor;
  final Set<String> _runningTaskIds = {};

  int _nextSequence = 0;

  TransferTask queueOperation({
    required TransferOperation operation,
    required List<String> sourcePaths,
    required String displayName,
    String? destinationPath,
    int? totalBytes,
  }) {
    final now = DateTime.now();
    final task = TransferTask(
      id: 'transfer-${now.microsecondsSinceEpoch}-${_nextSequence++}',
      operation: operation,
      sourcePaths: List.unmodifiable(sourcePaths),
      displayName: displayName,
      destinationPath: destinationPath,
      status: _initialStatusFor(operation, destinationPath),
      createdAt: now,
      updatedAt: now,
      progress: TransferProgress(totalBytes: totalBytes),
    );

    state = state.copyWith(tasks: [task, ...state.tasks]);
    _startIfReady(task.id);
    return task;
  }

  void setDestination({
    required String taskId,
    required String destinationPath,
  }) {
    _replaceTask(
      taskId,
      (task, now) => task.copyWith(
        destinationPath: destinationPath,
        status: TransferTaskStatus.queued,
        updatedAt: now,
      ),
    );
    _startIfReady(taskId);
  }

  void markRunning(String taskId) {
    _replaceTask(
      taskId,
      (task, now) => task.copyWith(
        status: TransferTaskStatus.running,
        updatedAt: now,
      ),
    );
  }

  void updateProgress({
    required String taskId,
    required int transferredBytes,
    int? totalBytes,
    String? currentItemPath,
  }) {
    final currentTask = _taskById(taskId);
    if (currentTask == null ||
        currentTask.status == TransferTaskStatus.cancelled) {
      return;
    }

    _replaceTask(
      taskId,
      (task, now) => task.copyWith(
        status: TransferTaskStatus.running,
        updatedAt: now,
        progress: TransferProgress(
          transferredBytes: transferredBytes,
          totalBytes: totalBytes ?? task.progress.totalBytes,
          currentItemPath: currentItemPath ?? task.progress.currentItemPath,
        ),
      ),
    );
  }

  void complete(String taskId) {
    final currentTask = _taskById(taskId);
    if (currentTask == null ||
        currentTask.status == TransferTaskStatus.cancelled) {
      return;
    }

    _replaceTask(
      taskId,
      (task, now) => task.copyWith(
        status: TransferTaskStatus.completed,
        updatedAt: now,
        progress: TransferProgress(
          transferredBytes: task.progress.totalBytes ?? 1,
          totalBytes: task.progress.totalBytes ?? 1,
          currentItemPath: task.progress.currentItemPath,
        ),
      ),
    );
  }

  void fail({
    required String taskId,
    required String message,
  }) {
    final currentTask = _taskById(taskId);
    if (currentTask == null ||
        currentTask.status == TransferTaskStatus.cancelled) {
      return;
    }

    _replaceTask(
      taskId,
      (task, now) => task.copyWith(
        status: TransferTaskStatus.failed,
        updatedAt: now,
        failureMessage: message,
      ),
    );
  }

  void retry(String taskId) {
    _replaceTask(
      taskId,
      (task, now) => task.copyWith(
        status: _initialStatusFor(task.operation, task.destinationPath),
        updatedAt: now,
        progress: const TransferProgress(),
        clearFailureMessage: true,
      ),
    );
    _startIfReady(taskId);
  }

  void cancel(String taskId) {
    _replaceTask(
      taskId,
      (task, now) => task.canCancel
          ? task.copyWith(
              status: TransferTaskStatus.cancelled,
              updatedAt: now,
            )
          : task,
    );
  }

  void clearFinished() {
    state = state.copyWith(
      tasks: [
        for (final task in state.tasks)
          if (!task.isFinished) task,
      ],
    );
  }

  void _startIfReady(String taskId) {
    final task = _taskById(taskId);
    if (task == null ||
        task.status != TransferTaskStatus.queued ||
        _runningTaskIds.contains(taskId)) {
      return;
    }

    _runningTaskIds.add(taskId);
    markRunning(taskId);

    unawaited(
      _executor.execute(
        task,
        onProgress: (progress) {
          updateProgress(
            taskId: taskId,
            transferredBytes: progress.transferredBytes,
            totalBytes: progress.totalBytes,
            currentItemPath: progress.currentItemPath,
          );
        },
      ).then((_) {
        complete(taskId);
      }).catchError((Object error) {
        fail(taskId: taskId, message: error.toString());
      }).whenComplete(() {
        _runningTaskIds.remove(taskId);
      }),
    );
  }

  TransferTask? _taskById(String taskId) {
    for (final task in state.tasks) {
      if (task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  TransferTaskStatus _initialStatusFor(
    TransferOperation operation,
    String? destinationPath,
  ) {
    if (operation.needsDestination &&
        (destinationPath == null || destinationPath.isEmpty)) {
      return TransferTaskStatus.awaitingDestination;
    }
    return TransferTaskStatus.queued;
  }

  void _replaceTask(
    String taskId,
    TransferTask Function(TransferTask task, DateTime now) update,
  ) {
    final now = DateTime.now();
    state = state.copyWith(
      tasks: [
        for (final task in state.tasks)
          if (task.id == taskId) update(task, now) else task,
      ],
    );
  }
}
