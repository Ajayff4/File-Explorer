import 'dart:async';

import 'package:file_explorer/features/transfers/data/repositories/transfer_executor_provider.dart';
import 'package:file_explorer/features/transfers/data/repositories/transfer_task_store_provider.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_executor.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_task_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transferControllerProvider =
    StateNotifierProvider<TransferController, TransferState>((ref) {
  final controller = TransferController(
    ref.read(transferExecutorProvider),
    ref.read(transferTaskStoreProvider),
  );
  unawaited(controller.loadPersistedTasks());
  return controller;
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
  TransferController(
    this._executor, [
    TransferTaskStore? taskStore,
  ])  : _taskStore = taskStore,
        super(const TransferState());

  final TransferExecutor _executor;
  final TransferTaskStore? _taskStore;
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
    _saveTask(task);
    _startIfReady(task.id);
    return task;
  }

  Future<void> loadPersistedTasks() async {
    final persistedTasks = await _taskStore?.loadTasks() ?? const [];
    if (persistedTasks.isEmpty || !mounted) {
      return;
    }

    final normalizedTasks = [
      for (final task in persistedTasks) _normalizeRestoredTask(task),
    ];
    final currentTaskIds = state.tasks.map((task) => task.id).toSet();
    state = state.copyWith(
      tasks: [
        ...state.tasks,
        for (final task in normalizedTasks)
          if (!currentTaskIds.contains(task.id)) task,
      ],
    );

    for (final task in normalizedTasks) {
      if (task.status == TransferTaskStatus.failed &&
          task.failureMessage == _interruptedFailureMessage) {
        _saveTask(task);
      }
      _startIfReady(task.id);
    }
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
    TransferFailureCode code = TransferFailureCode.unknown,
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
        failureCode: code,
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
        clearFailureCode: true,
      ),
    );
    _startIfReady(taskId);
  }

  void resolveConflict({
    required String taskId,
    required ConflictPolicy policy,
  }) {
    _replaceTask(
      taskId,
      (task, now) => task.copyWith(
        status: _initialStatusFor(task.operation, task.destinationPath),
        updatedAt: now,
        progress: const TransferProgress(),
        conflictPolicy: policy,
        clearFailureMessage: true,
        clearFailureCode: true,
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
    final finishedTaskIds = [
      for (final task in state.tasks)
        if (task.isFinished) task.id,
    ];
    state = state.copyWith(
      tasks: [
        for (final task in state.tasks)
          if (!task.isFinished) task,
      ],
    );
    unawaited(_taskStore?.deleteTasks(finishedTaskIds) ?? Future.value());
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
        if (error is TransferExecutionException) {
          fail(
            taskId: taskId,
            message: error.toString(),
            code: error.code,
          );
          return;
        }
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
    TransferTask? updatedTask;
    state = state.copyWith(
      tasks: [
        for (final task in state.tasks)
          if (task.id == taskId) updatedTask = update(task, now) else task,
      ],
    );
    final taskToSave = updatedTask;
    if (taskToSave != null) {
      _saveTask(taskToSave);
    }
  }

  TransferTask _normalizeRestoredTask(TransferTask task) {
    if (task.status != TransferTaskStatus.running) {
      return task;
    }
    return task.copyWith(
      status: TransferTaskStatus.failed,
      failureMessage: _interruptedFailureMessage,
      failureCode: TransferFailureCode.unknown,
      updatedAt: DateTime.now(),
    );
  }

  void _saveTask(TransferTask task) {
    unawaited(_taskStore?.saveTask(task) ?? Future.value());
  }
}

const _interruptedFailureMessage = 'Transfer interrupted before completion';
