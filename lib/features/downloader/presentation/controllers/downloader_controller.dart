import 'dart:async';
import 'dart:io';

import 'package:file_explorer/features/downloader/data/repositories/download_engine_provider.dart';
import 'package:file_explorer/features/downloader/data/repositories/download_task_store_provider.dart';
import 'package:file_explorer/features/downloader/data/repositories/downloader_settings_store_provider.dart';
import 'package:file_explorer/features/downloader/domain/entities/download_task.dart';
import 'package:file_explorer/features/downloader/domain/repositories/download_engine.dart';
import 'package:file_explorer/features/downloader/domain/repositories/download_task_store.dart';
import 'package:file_explorer/features/downloader/domain/repositories/downloader_settings_store.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

final downloaderControllerProvider =
    StateNotifierProvider<DownloaderController, DownloaderState>((ref) {
  final controller = DownloaderController(
    ref.read(downloadEngineProvider),
    taskStore: ref.read(downloadTaskStoreProvider),
    settingsStore: ref.read(downloaderSettingsStoreProvider),
    storageRepository: ref.read(storageRepositoryProvider),
  );
  unawaited(controller.initialize());
  return controller;
});

class DownloaderState {
  const DownloaderState({
    this.tasks = const [],
    this.settings = const DownloaderSettings(),
    this.isLoading = true,
  });

  final List<DownloadTask> tasks;
  final DownloaderSettings settings;
  final bool isLoading;

  List<DownloadTask> get activeTasks =>
      tasks.where((task) => !task.isFinished).toList();

  List<DownloadTask> get finishedTasks =>
      tasks.where((task) => task.isFinished).toList();

  int get queuedCount {
    return tasks
        .where((task) => task.status == DownloadTaskStatus.queued)
        .length;
  }

  int get runningCount {
    return tasks
        .where((task) => task.status == DownloadTaskStatus.running)
        .length;
  }

  int get completedCount {
    return tasks
        .where((task) => task.status == DownloadTaskStatus.completed)
        .length;
  }

  int get failedCount {
    return tasks
        .where((task) => task.status == DownloadTaskStatus.failed)
        .length;
  }

  int get pendingCount => queuedCount + runningCount;

  DownloadTask? taskById(String id) {
    for (final task in tasks) {
      if (task.id == id) {
        return task;
      }
    }
    return null;
  }

  DownloaderState copyWith({
    List<DownloadTask>? tasks,
    DownloaderSettings? settings,
    bool? isLoading,
  }) {
    return DownloaderState(
      tasks: tasks ?? this.tasks,
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DownloaderController extends StateNotifier<DownloaderState> {
  DownloaderController(
    this._engine, {
    DownloadTaskStore? taskStore,
    DownloaderSettingsStore? settingsStore,
    StorageRepository? storageRepository,
  })  : _taskStore = taskStore,
        _settingsStore = settingsStore,
        _storageRepository = storageRepository,
        super(const DownloaderState());

  final DownloadEngine _engine;
  final DownloadTaskStore? _taskStore;
  final DownloaderSettingsStore? _settingsStore;
  final StorageRepository? _storageRepository;
  final Set<String> _runningTaskIds = {};

  StreamSubscription<DownloaderEvent>? _eventSubscription;
  int _nextSequence = 0;

  Future<void> initialize() async {
    _eventSubscription = _engine.events().listen(_onEvent);

    var settings = const DownloaderSettings();
    try {
      settings = await _settingsStore?.load() ?? const DownloaderSettings();
    } catch (_) {
      // A broken/corrupt store must not prevent event delivery or task
      // lifecycle; fall back to defaults and let _saveTask failures surface
      // separately.
    }
    if (settings.outputDirectory.isEmpty) {
      settings = settings.copyWith(
        outputDirectory: await _resolveDefaultOutputDirectory(),
      );
      await _settingsStore?.save(settings);
    }
    if (!mounted) {
      return;
    }
    state = state.copyWith(settings: settings, isLoading: false);

    var persistedTasks = const <DownloadTask>[];
    try {
      persistedTasks = await _taskStore?.loadTasks() ?? const [];
    } catch (_) {
      persistedTasks = const [];
    }
    if (!mounted) {
      return;
    }
    final currentTaskIds = state.tasks.map((task) => task.id).toSet();
    final normalizedTasks = [
      for (final task in persistedTasks)
        if (!currentTaskIds.contains(task.id)) _normalizeRestoredTask(task),
    ];
    state = state.copyWith(tasks: [...state.tasks, ...normalizedTasks]);

    for (final task in normalizedTasks) {
      if (task.status == DownloadTaskStatus.failed &&
          task.failureMessage == _interruptedFailureMessage) {
        _saveTask(task);
      }
      _startIfReady(task.id);
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  void setMaxConcurrentDownloads(int maxConcurrent) {
    final clamped = maxConcurrent.clamp(1, 16);
    final updated = state.settings.copyWith(maxConcurrentDownloads: clamped);
    state = state.copyWith(settings: updated);
    unawaited(_settingsStore?.save(updated) ?? Future.value());
    _tryStartNext();
  }

  Future<String> _resolveDefaultOutputDirectory() async {
    final volumes = await _storageRepository?.getStorageVolumes() ?? const [];
    if (volumes.isNotEmpty) {
      final root = volumes.first.path;
      final download = '$root/Download';
      try {
        if (await Directory(download).exists()) {
          return download;
        }
      } on FileSystemException {
        // fall through to the volume root
      }
      return root;
    }
    return '/';
  }

  void setOutputDirectory(String directory) {
    final updated = state.settings.copyWith(outputDirectory: directory);
    state = state.copyWith(settings: updated);
    unawaited(_settingsStore?.save(updated) ?? Future.value());
  }

  DownloadTask enqueue({
    required String url,
    DownloadMediaType mediaType = DownloadMediaType.video,
    DownloadQuality quality = DownloadQuality.auto,
    DownloadAudioFormat audioFormat = DownloadAudioFormat.original,
    bool playlist = false,
  }) {
    final trimmedUrl = url.trim();
    final now = DateTime.now();
    final outputDirectory = state.settings.outputDirectory;
    final task = DownloadTask(
      id: 'download-${now.microsecondsSinceEpoch}-${_nextSequence++}',
      url: trimmedUrl,
      mediaType: mediaType,
      quality: quality,
      audioFormat: audioFormat,
      playlist: playlist,
      status: DownloadTaskStatus.queued,
      createdAt: now,
      updatedAt: now,
      outputDirectory: outputDirectory,
    );

    state = state.copyWith(tasks: [task, ...state.tasks]);
    _saveTask(task);
    _startIfReady(task.id);
    return task;
  }

  void retry(String taskId) {
    final currentTask = state.taskById(taskId);
    if (currentTask == null || !currentTask.canRetry) {
      return;
    }
    _replaceTask(
      taskId,
      (task, now) => task.copyWith(
        status: DownloadTaskStatus.queued,
        updatedAt: now,
        progress: const DownloadProgress(),
        clearFailureMessage: true,
      ),
    );
    _startIfReady(taskId);
  }

  void cancel(String taskId) {
    final currentTask = state.taskById(taskId);
    if (currentTask == null || !currentTask.canCancel) {
      return;
    }
    if (currentTask.status == DownloadTaskStatus.running ||
        currentTask.status == DownloadTaskStatus.paused) {
      unawaited(_engine.cancel(taskId));
      _runningTaskIds.add(taskId);
    }
    _replaceTask(
      taskId,
      (task, now) => task.copyWith(
        status: DownloadTaskStatus.cancelled,
        updatedAt: now,
      ),
    );
  }

  void pause(String taskId) {
    final currentTask = state.taskById(taskId);
    if (currentTask == null || !currentTask.canPause) {
      return;
    }
    unawaited(_engine.pause(taskId));
    _replaceTask(
      taskId,
      (task, now) => task.copyWith(
        status: DownloadTaskStatus.paused,
        updatedAt: now,
        progress: task.progress.copyWith(speedBytesPerSecond: 0),
      ),
    );
  }

  void resume(String taskId) {
    final currentTask = state.taskById(taskId);
    if (currentTask == null || !currentTask.canResume) {
      return;
    }
    unawaited(_engine.resume(taskId));
    _replaceTask(
      taskId,
      (task, now) => task.copyWith(
        status: DownloadTaskStatus.running,
        updatedAt: now,
      ),
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

  /// Starts a queued download if concurrency allows.
  void _startIfReady(String taskId) {
    final task = state.taskById(taskId);
    if (task == null ||
        task.status != DownloadTaskStatus.queued ||
        _runningTaskIds.contains(taskId)) {
      return;
    }

    final runningCount = state.tasks
        .where((task) => task.status == DownloadTaskStatus.running)
        .length;
    if (runningCount >= state.settings.maxConcurrentDownloads) {
      return;
    }

    _runningTaskIds.add(taskId);
    _replaceTask(
      taskId,
      (task, now) => task.copyWith(
        status: DownloadTaskStatus.running,
        updatedAt: now,
      ),
    );

    unawaited(
      _engine
          .start(
        taskId: taskId,
        url: task.url,
        mediaType: task.mediaType,
        quality: task.quality,
        audioFormat: task.audioFormat,
        playlist: task.playlist,
        outputDirectory: task.outputDirectory,
      )
          .catchError((Object error) {
        _markFailed(taskId, error.toString());
      }),
    );
  }

  void _onEvent(DownloaderEvent event) {
    final taskId = event.taskId;
    final task = state.taskById(taskId);
    if (task == null || task.status == DownloadTaskStatus.cancelled) {
      _runningTaskIds.remove(taskId);
      _tryStartNext();
      return;
    }

    switch (event.kind) {
      case DownloaderEventKind.resolved:
        if (event.title != null && event.title!.isNotEmpty) {
          _replaceTask(
            taskId,
            (task, now) => task.copyWith(
              title: event.title,
              updatedAt: now,
            ),
          );
        }
      case DownloaderEventKind.progress:
        _replaceTask(
          taskId,
          (task, now) => task.copyWith(
            status: task.status == DownloadTaskStatus.paused
                ? DownloadTaskStatus.paused
                : DownloadTaskStatus.running,
            updatedAt: now,
            progress: DownloadProgress(
              transferredBytes:
                  event.transferredBytes ?? task.progress.transferredBytes,
              totalBytes: event.totalBytes ?? task.progress.totalBytes,
              speedBytesPerSecond: event.speedBytesPerSecond ??
                  task.progress.speedBytesPerSecond,
            ),
          ),
        );
      case DownloaderEventKind.paused:
        _replaceTask(
          taskId,
          (task, now) => task.copyWith(
            status: DownloadTaskStatus.paused,
            updatedAt: now,
            progress: task.progress.copyWith(speedBytesPerSecond: 0),
          ),
        );
      case DownloaderEventKind.completed:
        _runningTaskIds.remove(taskId);
        _replaceTask(
          taskId,
          (task, now) => task.copyWith(
            status: DownloadTaskStatus.completed,
            updatedAt: now,
            title:
                (event.title?.isNotEmpty ?? false) ? event.title : task.title,
            progress: DownloadProgress(
              transferredBytes:
                  event.transferredBytes ?? task.progress.totalBytes ?? 1,
              totalBytes: event.totalBytes ?? task.progress.totalBytes,
              speedBytesPerSecond: 0,
            ),
            fileName: event.fileName ?? task.fileName,
          ),
        );
        _tryStartNext();
      case DownloaderEventKind.failed:
        _runningTaskIds.remove(taskId);
        _markFailed(taskId, event.message ?? 'Download failed');
      case DownloaderEventKind.cancelled:
        _runningTaskIds.remove(taskId);
        _tryStartNext();
    }
  }

  void _markFailed(String taskId, String message) {
    final currentTask = state.taskById(taskId);
    if (currentTask == null ||
        currentTask.status == DownloadTaskStatus.cancelled) {
      _runningTaskIds.remove(taskId);
      _tryStartNext();
      return;
    }
    _replaceTask(
      taskId,
      (task, now) => task.copyWith(
        status: DownloadTaskStatus.failed,
        updatedAt: now,
        failureMessage: message,
      ),
    );
    _tryStartNext();
  }

  void _tryStartNext() {
    final queuedTasks = [
      for (final task in state.tasks)
        if (task.status == DownloadTaskStatus.queued) task,
    ];
    for (final task in queuedTasks) {
      _startIfReady(task.id);
    }
  }

  void _replaceTask(
    String taskId,
    DownloadTask Function(DownloadTask task, DateTime now) update,
  ) {
    final now = DateTime.now();
    DownloadTask? updatedTask;
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

  DownloadTask _normalizeRestoredTask(DownloadTask task) {
    if (task.status != DownloadTaskStatus.running &&
        task.status != DownloadTaskStatus.paused) {
      return task;
    }
    return task.copyWith(
      status: DownloadTaskStatus.failed,
      failureMessage: _interruptedFailureMessage,
      updatedAt: DateTime.now(),
    );
  }

  void _saveTask(DownloadTask task) {
    unawaited(_taskStore?.saveTask(task) ?? Future.value());
  }
}

const _interruptedFailureMessage = 'Download interrupted before completion';
