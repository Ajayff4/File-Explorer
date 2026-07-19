import 'package:file_explorer/features/transfers/data/repositories/in_memory_transfer_task_store.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_task_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

TransferTaskStore createTransferTaskStore(Ref ref) {
  return InMemoryTransferTaskStore();
}
