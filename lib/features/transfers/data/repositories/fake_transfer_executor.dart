import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_executor.dart';

class FakeTransferExecutor implements TransferExecutor {
  const FakeTransferExecutor();

  @override
  Future<void> execute(
    TransferTask task, {
    required TransferProgressCallback onProgress,
  }) async {
    final totalBytes = task.progress.totalBytes ?? 1;
    onProgress(
      TransferProgress(
        transferredBytes: totalBytes,
        totalBytes: totalBytes,
        currentItemPath:
            task.sourcePaths.isEmpty ? null : task.sourcePaths.first,
      ),
    );
  }
}
