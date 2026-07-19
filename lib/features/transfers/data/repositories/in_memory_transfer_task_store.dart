import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_task_store.dart';

class InMemoryTransferTaskStore implements TransferTaskStore {
  final Map<String, TransferTask> _tasks = {};

  @override
  Future<List<TransferTask>> loadTasks() async {
    final tasks = _tasks.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return tasks;
  }

  @override
  Future<void> saveTask(TransferTask task) async {
    _tasks[task.id] = task;
  }

  @override
  Future<void> deleteTasks(List<String> taskIds) async {
    for (final taskId in taskIds) {
      _tasks.remove(taskId);
    }
  }
}
