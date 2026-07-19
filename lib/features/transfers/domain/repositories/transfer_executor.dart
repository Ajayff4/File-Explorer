import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';

typedef TransferProgressCallback = void Function(TransferProgress progress);

class TransferExecutionException implements Exception {
  const TransferExecutionException({
    required this.code,
    required this.message,
    this.path,
  });

  final TransferFailureCode code;
  final String message;
  final String? path;

  @override
  String toString() {
    final failedPath = path;
    if (failedPath == null || failedPath.isEmpty) {
      return message;
    }
    return '$message: $failedPath';
  }
}

abstract interface class TransferExecutor {
  Future<void> execute(
    TransferTask task, {
    required TransferProgressCallback onProgress,
  });
}
