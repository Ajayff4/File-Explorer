import 'package:file_explorer/features/downloader/domain/entities/download_task.dart';

enum DownloaderEventKind { resolved, progress, completed, failed, cancelled, paused }

class DownloaderEvent {
  const DownloaderEvent({
    required this.taskId,
    required this.kind,
    this.title,
    this.transferredBytes,
    this.totalBytes,
    this.speedBytesPerSecond,
    this.fileName,
    this.message,
  });

  final String taskId;
  final DownloaderEventKind kind;
  final String? title;
  final int? transferredBytes;
  final int? totalBytes;
  final double? speedBytesPerSecond;
  final String? fileName;
  final String? message;

  DownloaderEvent copyWith({
    String? taskId,
    DownloaderEventKind? kind,
    String? title,
    int? transferredBytes,
    int? totalBytes,
    double? speedBytesPerSecond,
    String? fileName,
    String? message,
    bool clearTitle = false,
    bool clearFileName = false,
    bool clearMessage = false,
  }) {
    return DownloaderEvent(
      taskId: taskId ?? this.taskId,
      kind: kind ?? this.kind,
      title: clearTitle ? null : title ?? this.title,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBytesPerSecond:
          speedBytesPerSecond ?? this.speedBytesPerSecond,
      fileName: clearFileName ? null : fileName ?? this.fileName,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

/// Resolved metadata for a media URL before a download starts.
class MediaInfo {
  const MediaInfo({
    required this.title,
    this.thumbnailUrl,
    this.durationSeconds,
    this.isPlaylist = false,
  });

  final String title;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final bool isPlaylist;
}

abstract interface class DownloadEngine {
  /// Emits per-task download events (started/resolved/progress/completed/...).
  Stream<DownloaderEvent> events();

  /// Resolves URL metadata (title, thumbnail) without downloading.
  Future<MediaInfo> resolve({
    required String url,
    required DownloadMediaType mediaType,
  });

  /// Begins downloading [url] into [outputDirectory], emitting [DownloaderEvent]s
  /// on [events()] keyed by [taskId].
  Future<void> start({
    required String taskId,
    required String url,
    required DownloadMediaType mediaType,
    required String outputDirectory,
    DownloadQuality quality = DownloadQuality.auto,
  });

  /// Requests cancellation of an in-flight download.
  Future<void> cancel(String taskId);

  /// Requests a temporary pause of an in-flight download.
  Future<void> pause(String taskId);

  /// Resumes a previously paused download.
  Future<void> resume(String taskId);

  /// Checks PyPI for a newer yt-dlp release than the one bundled in the app.
  Future<YtDlpUpdateInfo> checkUpdate();

  /// Downloads the latest yt-dlp release into app storage and loads it.
  Future<YtDlpApplyResult> applyUpdate();
}

/// Result of a yt-dlp update check.
class YtDlpUpdateInfo {
  const YtDlpUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.updateAvailable,
    this.error,
  });

  final String currentVersion;
  final String latestVersion;
  final bool updateAvailable;
  final String? error;

  bool get hasError => error != null && error!.isNotEmpty;
}

/// Result of applying a yt-dlp update.
class YtDlpApplyResult {
  const YtDlpApplyResult({
    required this.applied,
    required this.version,
    this.message,
  });

  final bool applied;
  final String version;
  final String? message;
}
