import 'dart:async';

import 'package:file_explorer/features/downloader/data/repositories/fake_download_engine.dart';
import 'package:file_explorer/features/downloader/data/repositories/in_memory_download_task_store.dart';
import 'package:file_explorer/features/downloader/data/repositories/in_memory_downloader_settings_store.dart';
import 'package:file_explorer/features/downloader/domain/entities/download_task.dart';
import 'package:file_explorer/features/downloader/domain/repositories/download_engine.dart';
import 'package:file_explorer/features/downloader/domain/repositories/downloader_settings_store.dart';
import 'package:file_explorer/features/downloader/presentation/controllers/downloader_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('enqueues a task and completes it with progress through the engine',
      () async {
    final engine = _HoldingDownloadEngine();
    final controller = DownloaderController(engine);
    await controller.initialize();

    final task = controller.enqueue(
      url: 'https://example.com/video',
      mediaType: DownloadMediaType.video,
    );

    expect(controller.state.tasks.single.status, DownloadTaskStatus.running);
    expect(
        controller.state.tasks.single.displayName, 'https://example.com/video');
    expect(engine.startedTaskIds, [task.id]);

    engine.complete(task.id);
    await _pumpEventQueue();

    final completedTask = controller.state.tasks.single;
    expect(completedTask.status, DownloadTaskStatus.completed);
    expect(completedTask.title, 'Held title');
    expect(completedTask.progress.transferredBytes, 100);
    expect(completedTask.progress.fraction, 1);
    expect(completedTask.fileName, '${task.id}_output.mp4');
    expect(controller.state.completedCount, 1);
    expect(controller.state.pendingCount, 0);
  });

  test('marks failed tasks with the engine failure message', () async {
    final engine = FakeDownloadEngine()..shouldFail = true;
    final controller = DownloaderController(engine);
    await controller.initialize();

    controller.enqueue(url: 'https://example.com/broken');
    await _pumpEventQueue();

    final failedTask = controller.state.tasks.single;
    expect(failedTask.status, DownloadTaskStatus.failed);
    expect(failedTask.failureMessage, 'Simulated failure');
    expect(controller.state.failedCount, 1);

    controller.clearFinished();
    expect(controller.state.tasks, isEmpty);
  });

  test('retries a failed task without keeping the old failure message',
      () async {
    final engine = FakeDownloadEngine()..shouldFail = true;
    final controller = DownloaderController(engine);
    await controller.initialize();

    controller.enqueue(url: 'https://example.com/retry');
    await _pumpEventQueue();

    final failedTask = controller.state.tasks.single;
    expect(failedTask.status, DownloadTaskStatus.failed);

    engine.shouldFail = false;
    controller.retry(failedTask.id);
    await _pumpEventQueue();

    final retriedTask = controller.state.tasks.single;
    expect(retriedTask.status, DownloadTaskStatus.completed);
    expect(retriedTask.failureMessage, isNull);
  });

  test('cancels a running download through the engine', () async {
    final engine = _HoldingDownloadEngine();
    final controller = DownloaderController(engine);
    await controller.initialize();

    final task = controller.enqueue(url: 'https://example.com/cancel');
    expect(controller.state.tasks.single.status, DownloadTaskStatus.running);

    controller.cancel(task.id);
    await _pumpEventQueue();

    expect(engine.cancelledTaskIds, contains(task.id));
    expect(controller.state.tasks.single.status, DownloadTaskStatus.cancelled);
  });

  test('limits concurrent downloads to the configured maximum', () async {
    final engine = _HoldingDownloadEngine();
    final controller = DownloaderController(engine);
    await controller.initialize();
    controller.setMaxConcurrentDownloads(2);

    for (var i = 0; i < 4; i++) {
      controller.enqueue(url: 'https://example.com/download/$i');
    }
    await _pumpEventQueue();

    expect(controller.state.runningCount, 2);
    expect(controller.state.queuedCount, 2);
    expect(engine.startedTaskIds.length, 2);
  });

  test('starts the next download when one finishes', () async {
    final engine = _HoldingDownloadEngine();
    final controller = DownloaderController(engine);
    await controller.initialize();
    controller.setMaxConcurrentDownloads(1);

    final first = controller.enqueue(url: 'https://example.com/1');
    final second = controller.enqueue(url: 'https://example.com/2');
    expect(controller.state.runningCount, 1);
    expect(controller.state.queuedCount, 1);

    engine.complete(first.id);
    await _pumpEventQueue();

    expect(engine.startedTaskIds, [first.id, second.id]);
    expect(controller.state.runningCount, 1);
    expect(controller.state.queuedCount, 0);
  });

  test('carries audio format and playlist flag through to the engine',
      () async {
    final engine = FakeDownloadEngine();
    final controller = DownloaderController(engine);
    await controller.initialize();

    controller.enqueue(
      url: 'https://example.com/mp3',
      mediaType: DownloadMediaType.audio,
      audioFormat: DownloadAudioFormat.mp3,
      playlist: true,
    );
    await _pumpEventQueue();

    final task = controller.state.tasks.single;
    expect(task.audioFormat, DownloadAudioFormat.mp3);
    expect(task.playlist, isTrue);
    expect(engine.startRequests.single.audioFormat, DownloadAudioFormat.mp3);
    expect(engine.startRequests.single.playlist, isTrue);
  });

  test('persists tasks and restores them on load', () async {
    final store = InMemoryDownloadTaskStore();
    final engine = FakeDownloadEngine();
    final controller = DownloaderController(engine, taskStore: store);
    await controller.initialize();

    final task = controller.enqueue(url: 'https://example.com/persisted');
    await _pumpEventQueue();

    expect((await store.loadTasks()).single.id, task.id);
    expect(
      (await store.loadTasks()).single.status,
      DownloadTaskStatus.completed,
    );

    final restoredController = DownloaderController(engine, taskStore: store);
    await restoredController.initialize();
    await _pumpEventQueue();

    final restoredTask = restoredController.state.tasks.single;
    expect(restoredTask.status, DownloadTaskStatus.completed);
    expect(restoredController.state.tasks.single.id, task.id);
  });

  test('restores interrupted running tasks as failed', () async {
    final store = InMemoryDownloadTaskStore();
    await store.saveTask(_storedTask(status: DownloadTaskStatus.running));

    final controller = DownloaderController(
      FakeDownloadEngine(),
      taskStore: store,
    );
    await controller.initialize();
    await _pumpEventQueue();

    final restoredTask = controller.state.tasks.single;
    expect(restoredTask.status, DownloadTaskStatus.failed);
    expect(restoredTask.failureMessage, contains('interrupted'));
  });

  test('updates settings and persists them', () async {
    final settingsStore = InMemoryDownloaderSettingsStore();
    final controller = DownloaderController(
      FakeDownloadEngine(),
      settingsStore: settingsStore,
    );
    await controller.initialize();

    controller.setMaxConcurrentDownloads(4);
    controller.setOutputDirectory('/storage/emulated/0/Download');

    expect(controller.state.settings.maxConcurrentDownloads, 4);
    expect(
      controller.state.settings.outputDirectory,
      '/storage/emulated/0/Download',
    );

    final saved = await settingsStore.load();
    expect(saved.maxConcurrentDownloads, 4);
    expect(saved.outputDirectory, '/storage/emulated/0/Download');
  });

  test('loads persisted settings on initialize', () async {
    final settingsStore = InMemoryDownloaderSettingsStore();
    await settingsStore.save(
      const DownloaderSettings(
        maxConcurrentDownloads: 6,
        outputDirectory: '/storage/emulated/0/Download',
      ),
    );

    final controller = DownloaderController(
      FakeDownloadEngine(),
      settingsStore: settingsStore,
    );
    await controller.initialize();

    expect(controller.state.settings.maxConcurrentDownloads, 6);
    expect(controller.state.isLoading, false);
  });

  test('pauses a running download through the engine', () async {
    final engine = _HoldingDownloadEngine();
    final controller = DownloaderController(engine);
    await controller.initialize();

    final task = controller.enqueue(url: 'https://example.com/pause');
    expect(controller.state.tasks.single.status, DownloadTaskStatus.running);

    controller.pause(task.id);
    await _pumpEventQueue();

    expect(engine.pausedTaskIds, contains(task.id));
    expect(controller.state.tasks.single.status, DownloadTaskStatus.paused);
  });

  test('resumes a paused download through the engine', () async {
    final engine = _HoldingDownloadEngine();
    final controller = DownloaderController(engine);
    await controller.initialize();

    final task = controller.enqueue(url: 'https://example.com/resume');
    controller.pause(task.id);
    await _pumpEventQueue();
    expect(controller.state.tasks.single.status, DownloadTaskStatus.paused);

    controller.resume(task.id);
    await _pumpEventQueue();

    expect(engine.resumedTaskIds, contains(task.id));
    expect(controller.state.tasks.single.status, DownloadTaskStatus.running);
  });

  test('ignores pause on a non-running task', () async {
    final engine = FakeDownloadEngine()..shouldFail = true;
    final controller = DownloaderController(engine);
    await controller.initialize();

    controller.enqueue(url: 'https://example.com/ignore-pause');
    await _pumpEventQueue();
    expect(controller.state.tasks.single.status, DownloadTaskStatus.failed);

    controller.pause(controller.state.tasks.single.id);
    await _pumpEventQueue();

    expect(controller.state.tasks.single.status, DownloadTaskStatus.failed);
  });

  test('cancels a paused download through the engine', () async {
    final engine = _HoldingDownloadEngine();
    final controller = DownloaderController(engine);
    await controller.initialize();

    final task = controller.enqueue(url: 'https://example.com/cancel-paused');
    controller.pause(task.id);
    await _pumpEventQueue();

    controller.cancel(task.id);
    await _pumpEventQueue();

    expect(engine.cancelledTaskIds, contains(task.id));
    expect(controller.state.tasks.single.status, DownloadTaskStatus.cancelled);
  });

  test('restores interrupted paused tasks as failed', () async {
    final store = InMemoryDownloadTaskStore();
    await store.saveTask(_storedTask(status: DownloadTaskStatus.paused));

    final controller = DownloaderController(
      FakeDownloadEngine(),
      taskStore: store,
    );
    await controller.initialize();
    await _pumpEventQueue();

    final restoredTask = controller.state.tasks.single;
    expect(restoredTask.status, DownloadTaskStatus.failed);
    expect(restoredTask.failureMessage, contains('interrupted'));
  });
}

Future<void> _pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

DownloadTask _storedTask({required DownloadTaskStatus status}) {
  final now = DateTime(2026);
  return DownloadTask(
    id: 'stored-task',
    url: 'https://example.com/stored',
    mediaType: DownloadMediaType.video,
    status: status,
    createdAt: now,
    updatedAt: now,
    outputDirectory: '',
  );
}

/// Engine that starts downloads but does not emit progress/completion until
/// told to, so tests can observe queueing, cancellation, and concurrency.
class _HoldingDownloadEngine implements DownloadEngine {
  final _controller = StreamController<DownloaderEvent>.broadcast();
  final startedTaskIds = <String>[];
  final cancelledTaskIds = <String>[];
  final pausedTaskIds = <String>[];
  final resumedTaskIds = <String>[];
  final _completed = <String>{};

  @override
  Stream<DownloaderEvent> events() => _controller.stream;

  @override
  Future<MediaInfo> resolve({
    required String url,
    required DownloadMediaType mediaType,
  }) async {
    return MediaInfo(title: 'Held $mediaType title');
  }

  @override
  Future<void> start({
    required String taskId,
    required String url,
    required DownloadMediaType mediaType,
    required String outputDirectory,
    DownloadQuality quality = DownloadQuality.auto,
    DownloadAudioFormat audioFormat = DownloadAudioFormat.original,
    bool playlist = false,
  }) async {
    startedTaskIds.add(taskId);
    _controller.add(
      DownloaderEvent(
        taskId: taskId,
        kind: DownloaderEventKind.resolved,
        title: 'Held $mediaType title',
      ),
    );
    if (_completed.contains(taskId)) {
      _emitComplete(taskId);
    }
  }

  void complete(String taskId) {
    _completed.add(taskId);
    _emitComplete(taskId);
  }

  void _emitComplete(String taskId) {
    _controller.add(
      DownloaderEvent(
        taskId: taskId,
        kind: DownloaderEventKind.progress,
        transferredBytes: 100,
        totalBytes: 100,
        speedBytesPerSecond: 50,
      ),
    );
    _controller.add(
      DownloaderEvent(
        taskId: taskId,
        kind: DownloaderEventKind.completed,
        title: 'Held title',
        transferredBytes: 100,
        totalBytes: 100,
        fileName: '${taskId}_output.mp4',
      ),
    );
  }

  @override
  Future<void> cancel(String taskId) async {
    cancelledTaskIds.add(taskId);
    _controller.add(
      DownloaderEvent(
        taskId: taskId,
        kind: DownloaderEventKind.cancelled,
      ),
    );
  }

  @override
  Future<void> pause(String taskId) async {
    pausedTaskIds.add(taskId);
    _controller.add(
      DownloaderEvent(
        taskId: taskId,
        kind: DownloaderEventKind.paused,
      ),
    );
  }

  @override
  Future<void> resume(String taskId) async {
    resumedTaskIds.add(taskId);
  }

  @override
  Future<YtDlpUpdateInfo> checkUpdate() async {
    return const YtDlpUpdateInfo(
      currentVersion: '0.0.0-fake',
      latestVersion: '0.0.0-fake',
      updateAvailable: false,
    );
  }

  @override
  Future<YtDlpApplyResult> applyUpdate() async {
    return const YtDlpApplyResult(
      applied: false,
      version: '0.0.0-fake',
      message: 'No update available',
    );
  }
}
