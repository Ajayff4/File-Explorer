enum TransferOperation {
  copy,
  move,
  delete,
  rename,
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
    this.failureMessage,
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
  final String? failureMessage;

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
    String? failureMessage,
    bool clearFailureMessage = false,
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
      failureMessage:
          clearFailureMessage ? null : failureMessage ?? this.failureMessage,
    );
  }
}

extension TransferOperationLabels on TransferOperation {
  String get label {
    return switch (this) {
      TransferOperation.copy => 'Copy',
      TransferOperation.move => 'Move',
      TransferOperation.delete => 'Delete',
      TransferOperation.rename => 'Rename',
    };
  }

  bool get needsDestination {
    return switch (this) {
      TransferOperation.copy ||
      TransferOperation.move ||
      TransferOperation.rename =>
        true,
      TransferOperation.delete => false,
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
