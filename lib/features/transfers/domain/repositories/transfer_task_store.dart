import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';

abstract interface class TransferTaskStore {
  Future<List<TransferTask>> loadTasks();
  Future<void> saveTask(TransferTask task);
  Future<void> deleteTasks(List<String> taskIds);
}
