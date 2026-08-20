import 'package:file_explorer/features/downloader/domain/entities/download_task.dart';
import 'package:file_explorer/features/downloader/domain/repositories/download_task_store.dart';

class InMemoryDownloadTaskStore implements DownloadTaskStore {
  final Map<String, DownloadTask> _tasks = {};

  @override
  Future<List<DownloadTask>> loadTasks() async {
    final tasks = _tasks.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return tasks;
  }

  @override
  Future<void> saveTask(DownloadTask task) async {
    _tasks[task.id] = task;
  }

  @override
  Future<void> deleteTasks(List<String> taskIds) async {
    for (final taskId in taskIds) {
      _tasks.remove(taskId);
    }
  }
}
