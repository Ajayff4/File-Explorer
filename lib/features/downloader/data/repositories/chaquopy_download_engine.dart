import 'dart:async';

import 'package:file_explorer/features/downloader/domain/entities/download_task.dart';
import 'package:file_explorer/features/downloader/domain/repositories/download_engine.dart';
import 'package:flutter/services.dart';

/// Android-only download engine backed by a Chaquopy Python runtime running
/// yt-dlp in MainActivity.kt.
///
/// Progress is streamed from Python through an EventChannel; lifecycle and
/// control calls go through a MethodChannel.
class ChaquopyDownloadEngine implements DownloadEngine {
  ChaquopyDownloadEngine({
    MethodChannel methodChannel = const MethodChannel(
      'com.ajayff4.fileexplorer/downloader',
    ),
    EventChannel eventChannel = const EventChannel(
      'com.ajayff4.fileexplorer/downloader/events',
    ),
  })  : _methodChannel = methodChannel,
        _eventChannel = eventChannel;

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<DownloaderEvent>? _events;

  @override
  Stream<DownloaderEvent> events() {
    return _events ??=
        _eventChannel.receiveBroadcastStream().map(_eventFromPayload);
  }

  @override
  Future<MediaInfo> resolve({
    required String url,
    required DownloadMediaType mediaType,
  }) async {
    final payload = await _methodChannel.invokeMapMethod<Object?, Object?>(
          'resolve',
          {
            'url': url,
            'mediaType': mediaType.name,
          },
        ) ??
        const <Object?, Object?>{};

    return MediaInfo(
      title: payload['title']?.toString() ?? _fallbackTitle(url),
      thumbnailUrl: payload['thumbnail']?.toString(),
      durationSeconds: _intFrom(payload['durationSeconds']),
      isPlaylist: payload['isPlaylist'] == true,
    );
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
    await _methodChannel.invokeMethod<void>('start', {
      'taskId': taskId,
      'url': url,
      'mediaType': mediaType.name,
      'outputDirectory': outputDirectory,
      'quality': quality.name,
      'audioFormat': audioFormat.name,
      'playlist': playlist,
    });
  }

  @override
  Future<void> cancel(String taskId) async {
    await _methodChannel.invokeMethod<void>('cancel', {'taskId': taskId});
  }

  @override
  Future<void> pause(String taskId) async {
    await _methodChannel.invokeMethod<void>('pause', {'taskId': taskId});
  }

  @override
  Future<void> resume(String taskId) async {
    await _methodChannel.invokeMethod<void>('resume', {'taskId': taskId});
  }

  @override
  Future<YtDlpUpdateInfo> checkUpdate() async {
    final payload = await _methodChannel.invokeMapMethod<Object?, Object?>(
          'check_update',
        ) ??
        const <Object?, Object?>{};

    return YtDlpUpdateInfo(
      currentVersion: payload['currentVersion']?.toString() ?? '',
      latestVersion: payload['latestVersion']?.toString() ?? '',
      updateAvailable: payload['updateAvailable'] == true,
      error: payload['error']?.toString(),
    );
  }

  @override
  Future<YtDlpApplyResult> applyUpdate() async {
    final payload = await _methodChannel.invokeMapMethod<Object?, Object?>(
          'apply_update',
        ) ??
        const <Object?, Object?>{};

    return YtDlpApplyResult(
      applied: payload['applied'] == true,
      version: payload['version']?.toString() ?? '',
      message: payload['message']?.toString(),
    );
  }

  DownloaderEvent _eventFromPayload(Object? raw) {
    final payload =
        raw is Map<Object?, Object?> ? raw : const <Object?, Object?>{};
    final taskId = payload['taskId']?.toString() ?? '';
    final kind = switch (payload['kind']?.toString()) {
      'resolved' => DownloaderEventKind.resolved,
      'progress' => DownloaderEventKind.progress,
      'completed' => DownloaderEventKind.completed,
      'failed' => DownloaderEventKind.failed,
      'cancelled' => DownloaderEventKind.cancelled,
      'paused' => DownloaderEventKind.paused,
      _ => DownloaderEventKind.progress,
    };

    return DownloaderEvent(
      taskId: taskId,
      kind: kind,
      title: payload['title']?.toString(),
      transferredBytes: _intFrom(payload['transferredBytes']),
      totalBytes: _intFrom(payload['totalBytes']) == 0
          ? null
          : _intFrom(payload['totalBytes']),
      speedBytesPerSecond: _doubleFrom(payload['speedBytesPerSecond']),
      fileName: payload['fileName']?.toString(),
      message: payload['message']?.toString(),
    );
  }

  String _fallbackTitle(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isEmpty ? url : uri.host;
    } on FormatException {
      return url;
    }
  }

  int _intFrom(Object? value) {
    return switch (value) {
      int() => value,
      num() => value.toInt(),
      String() => int.tryParse(value) ?? 0,
      _ => 0,
    };
  }

  double _doubleFrom(Object? value) {
    return switch (value) {
      double() => value,
      num() => value.toDouble(),
      String() => double.tryParse(value) ?? 0,
      _ => 0,
    };
  }
}
