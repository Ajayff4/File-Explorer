import 'dart:async';

import 'package:file_explorer/features/downloader/domain/entities/download_task.dart';
import 'package:file_explorer/features/downloader/domain/repositories/download_engine.dart';

/// Test/stand-in engine that streams synthetic progress and completes
/// without touching the network.
class FakeDownloadEngine implements DownloadEngine {
  final StreamController<DownloaderEvent> _controller =
      StreamController<DownloaderEvent>.broadcast(sync: true);

  bool shouldFail = false;

  final List<String> startedTaskIds = [];
  final List<String> cancelledTaskIds = [];
  final List<String> pausedTaskIds = [];
  final List<String> resumedTaskIds = [];
  final List<({String url, DownloadMediaType mediaType})> resolveRequests =
      [];
  final List<
      ({
        String taskId,
        DownloadAudioFormat audioFormat,
        bool playlist,
      })> startRequests = [];

  @override
  Stream<DownloaderEvent> events() => _controller.stream;

  @override
  Future<MediaInfo> resolve({
    required String url,
    required DownloadMediaType mediaType,
  }) async {
    resolveRequests.add((url: url, mediaType: mediaType));
    return MediaInfo(title: 'Fake $mediaType title');
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
    startRequests.add(
      (
        taskId: taskId,
        audioFormat: audioFormat,
        playlist: playlist,
      ),
    );
    _controller.add(
      DownloaderEvent(
        taskId: taskId,
        kind: DownloaderEventKind.resolved,
        title: 'Fake $mediaType title',
      ),
    );
    if (shouldFail) {
      _controller.add(
        DownloaderEvent(
          taskId: taskId,
          kind: DownloaderEventKind.failed,
          message: 'Simulated failure',
        ),
      );
      return;
    }
    _controller.add(
      DownloaderEvent(
        taskId: taskId,
        kind: DownloaderEventKind.progress,
        transferredBytes: 512,
        totalBytes: 1024,
        speedBytesPerSecond: 256,
      ),
    );
    _controller.add(
      DownloaderEvent(
        taskId: taskId,
        kind: DownloaderEventKind.completed,
        title: 'Fake $mediaType title',
        transferredBytes: 1024,
        totalBytes: 1024,
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
