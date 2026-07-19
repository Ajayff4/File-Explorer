import 'package:file_explorer/features/transfers/data/repositories/local_transfer_executor_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/transfers/data/repositories/local_transfer_executor_io.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_executor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transferExecutorProvider = Provider<TransferExecutor>((ref) {
  return createTransferExecutor();
});
