import 'package:file_explorer/features/transfers/data/repositories/transfer_task_store_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/transfers/data/repositories/transfer_task_store_io.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_task_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transferTaskStoreProvider = Provider<TransferTaskStore>((ref) {
  return createTransferTaskStore(ref);
});
