enum TransferOperation {
  copy,
  move,
  delete,
  moveToTrash,
  rename,
  extractArchive,
  compressArchive,
}

enum TransferTaskStatus {
  awaitingDestination,
  queued,
  running,
  completed,
  failed,
  cancelled,
}

enum ConflictPolicy {
  ask,
  overwrite,
  skip,
  rename,
}

enum TransferFailureCode {
  destinationExists,
  sourceMissing,
  permissionDenied,
  unknown,
}

class TransferProgress {
  const TransferProgress({
    this.transferredBytes = 0,
    this.totalBytes,
    this.currentItemPath,
  });

  final int transferredBytes;
  final int? totalBytes;
  final String? currentItemPath;

  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) {
      return null;
    }
    return (transferredBytes / total).clamp(0, 1).toDouble();
  }
}

class TransferTask {
  const TransferTask({
    required this.id,
    required this.operation,
    required this.sourcePaths,
    required this.displayName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.destinationPath,
    this.progress = const TransferProgress(),
    this.conflictPolicy = ConflictPolicy.ask,
    this.archivePassword,
    this.archiveCompressionLevel,
    this.failureMessage,
    this.failureCode,
  });

  final String id;
  final TransferOperation operation;
  final List<String> sourcePaths;
  final String displayName;
  final TransferTaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? destinationPath;
  final TransferProgress progress;
  final ConflictPolicy conflictPolicy;
  final String? archivePassword;
  final int? archiveCompressionLevel;
  final String? failureMessage;
  final TransferFailureCode? failureCode;

  bool get isActive => status == TransferTaskStatus.running;

  bool get isFinished {
    return switch (status) {
      TransferTaskStatus.completed ||
      TransferTaskStatus.failed ||
      TransferTaskStatus.cancelled =>
        true,
      TransferTaskStatus.awaitingDestination ||
      TransferTaskStatus.queued ||
      TransferTaskStatus.running =>
        false,
    };
  }

  bool get canCancel {
    return switch (status) {
      TransferTaskStatus.awaitingDestination ||
      TransferTaskStatus.queued ||
      TransferTaskStatus.running =>
        true,
      TransferTaskStatus.completed ||
      TransferTaskStatus.failed ||
      TransferTaskStatus.cancelled =>
        false,
    };
  }

  bool get canRetry => status == TransferTaskStatus.failed;

  TransferTask copyWith({
    TransferTaskStatus? status,
    DateTime? updatedAt,
    String? destinationPath,
    TransferProgress? progress,
    ConflictPolicy? conflictPolicy,
    String? archivePassword,
    int? archiveCompressionLevel,
    String? failureMessage,
    TransferFailureCode? failureCode,
    bool clearFailureMessage = false,
    bool clearFailureCode = false,
  }) {
    return TransferTask(
      id: id,
      operation: operation,
      sourcePaths: sourcePaths,
      displayName: displayName,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      destinationPath: destinationPath ?? this.destinationPath,
      progress: progress ?? this.progress,
      conflictPolicy: conflictPolicy ?? this.conflictPolicy,
      archivePassword: archivePassword ?? this.archivePassword,
      archiveCompressionLevel:
          archiveCompressionLevel ?? this.archiveCompressionLevel,
      failureMessage:
          clearFailureMessage ? null : failureMessage ?? this.failureMessage,
      failureCode: clearFailureCode ? null : failureCode ?? this.failureCode,
    );
  }
}

extension TransferOperationLabels on TransferOperation {
  String get label {
    return switch (this) {
      TransferOperation.copy => 'Copy',
      TransferOperation.move => 'Move',
      TransferOperation.delete => 'Delete',
      TransferOperation.moveToTrash => 'Move to trash',
      TransferOperation.rename => 'Rename',
      TransferOperation.extractArchive => 'Extract',
      TransferOperation.compressArchive => 'Compress',
    };
  }

  bool get needsDestination {
    return switch (this) {
      TransferOperation.copy ||
      TransferOperation.move ||
      TransferOperation.rename =>
        true,
      TransferOperation.extractArchive ||
      TransferOperation.compressArchive ||
      TransferOperation.delete ||
      TransferOperation.moveToTrash =>
        false,
    };
  }
}

extension TransferTaskStatusLabels on TransferTaskStatus {
  String get label {
    return switch (this) {
      TransferTaskStatus.awaitingDestination => 'Needs destination',
      TransferTaskStatus.queued => 'Queued',
      TransferTaskStatus.running => 'Running',
      TransferTaskStatus.completed => 'Completed',
      TransferTaskStatus.failed => 'Failed',
      TransferTaskStatus.cancelled => 'Cancelled',
    };
  }
}
