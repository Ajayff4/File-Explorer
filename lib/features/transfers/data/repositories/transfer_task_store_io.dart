import 'package:file_explorer/features/transfers/data/repositories/drift_transfer_task_store.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_task_store.dart';
import 'package:file_explorer/shared/database/app_database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

TransferTaskStore createTransferTaskStore(Ref ref) {
  return DriftTransferTaskStore(ref.watch(appDatabaseProvider));
}
