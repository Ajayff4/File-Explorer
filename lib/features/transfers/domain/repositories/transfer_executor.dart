import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';

typedef TransferProgressCallback = void Function(TransferProgress progress);

abstract interface class TransferExecutor {
  Future<void> execute(
    TransferTask task, {
    required TransferProgressCallback onProgress,
  });
}
