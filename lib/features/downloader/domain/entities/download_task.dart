enum DownloadMediaType {
  video('Video'),
  audio('Audio');

  const DownloadMediaType(this.label);

  final String label;
}

enum DownloadQuality {
  auto('Auto'),
  p480('480p'),
  p720('720p'),
  p1080('1080p'),
  max('Max');

  const DownloadQuality(this.label);

  final String label;
}

enum DownloadTaskStatus {
  queued,
  running,
  completed,
  failed,
  cancelled,
  paused;

  String get label {
    return switch (this) {
      DownloadTaskStatus.queued => 'Queued',
      DownloadTaskStatus.running => 'Downloading',
      DownloadTaskStatus.completed => 'Completed',
      DownloadTaskStatus.failed => 'Failed',
      DownloadTaskStatus.cancelled => 'Cancelled',
      DownloadTaskStatus.paused => 'Paused',
    };
  }
}

class DownloadProgress {
  const DownloadProgress({
    this.transferredBytes = 0,
    this.totalBytes,
    this.speedBytesPerSecond = 0,
  });

  final int transferredBytes;
  final int? totalBytes;
  final double speedBytesPerSecond;

  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) {
      return null;
    }
    return (transferredBytes / total).clamp(0, 1).toDouble();
  }

  DownloadProgress copyWith({
    int? transferredBytes,
    int? totalBytes,
    double? speedBytesPerSecond,
  }) {
    return DownloadProgress(
      transferredBytes: transferredBytes ?? this.transferredBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBytesPerSecond:
          speedBytesPerSecond ?? this.speedBytesPerSecond,
    );
  }
}

class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.url,
    required this.mediaType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.outputDirectory,
    this.quality = DownloadQuality.auto,
    this.title,
    this.progress = const DownloadProgress(),
    this.fileName,
    this.failureMessage,
  });

  final String id;
  final String url;
  final DownloadMediaType mediaType;
  final DownloadTaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String outputDirectory;
  final DownloadQuality quality;
  final String? title;
  final DownloadProgress progress;
  final String? fileName;
  final String? failureMessage;

  bool get isFinished {
    return switch (status) {
      DownloadTaskStatus.queued ||
      DownloadTaskStatus.running ||
      DownloadTaskStatus.paused =>
        false,
      DownloadTaskStatus.completed ||
      DownloadTaskStatus.failed ||
      DownloadTaskStatus.cancelled =>
        true,
    };
  }

  bool get canCancel {
    return switch (status) {
      DownloadTaskStatus.queued ||
      DownloadTaskStatus.running ||
      DownloadTaskStatus.paused =>
        true,
      DownloadTaskStatus.completed ||
      DownloadTaskStatus.failed ||
      DownloadTaskStatus.cancelled =>
        false,
    };
  }

  bool get canRetry => status == DownloadTaskStatus.failed;

  bool get canPause => status == DownloadTaskStatus.running;

  bool get canResume => status == DownloadTaskStatus.paused;

  bool get canClear => isFinished;

  String get displayName {
    return switch (title) {
      final title? => title,
      null => url,
    };
  }

  String get savedPath {
    final name = fileName;
    if (name == null || name.isEmpty) {
      return '';
    }
    return '$outputDirectory/$name';
  }

  DownloadTask copyWith({
    DownloadTaskStatus? status,
    DateTime? updatedAt,
    String? title,
    DownloadProgress? progress,
    String? fileName,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return DownloadTask(
      id: id,
      url: url,
      mediaType: mediaType,
      quality: quality,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      outputDirectory: outputDirectory,
      title: title ?? this.title,
      progress: progress ?? this.progress,
      fileName: fileName ?? this.fileName,
      failureMessage:
          clearFailureMessage ? null : failureMessage ?? this.failureMessage,
    );
  }
}