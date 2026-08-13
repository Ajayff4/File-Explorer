import 'package:file_explorer/features/downloader/domain/entities/download_task.dart';

abstract interface class DownloadTaskStore {
  Future<List<DownloadTask>> loadTasks();

  Future<void> saveTask(DownloadTask task);

  Future<void> deleteTasks(List<String> taskIds);
}