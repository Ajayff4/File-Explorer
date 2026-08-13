import 'package:drift/drift.dart';
import 'package:file_explorer/features/downloader/domain/entities/download_task.dart';
import 'package:file_explorer/features/downloader/domain/repositories/download_task_store.dart';
import 'package:file_explorer/shared/database/app_database.dart';

class DriftDownloadTaskStore implements DownloadTaskStore {
  const DriftDownloadTaskStore(this._database);

  final AppDatabase _database;

  @override
  Future<List<DownloadTask>> loadTasks() async {
    final rows = await (_database.select(_database.downloadTaskRows)
          ..orderBy([
            (table) => OrderingTerm.desc(table.updatedAt),
          ]))
        .get();
    return rows.map(_toTask).toList();
  }

  @override
  Future<void> saveTask(DownloadTask task) {
    return _database.into(_database.downloadTaskRows).insertOnConflictUpdate(
          _toCompanion(task),
        );
  }

  @override
  Future<void> deleteTasks(List<String> taskIds) async {
    if (taskIds.isEmpty) {
      return;
    }
    await (_database.delete(_database.downloadTaskRows)
          ..where((table) => table.id.isIn(taskIds)))
        .go();
  }

  DownloadTask _toTask(DownloadTaskRow row) {
    return DownloadTask(
      id: row.id,
      url: row.url,
      mediaType: row.mediaType,
      title: row.title,
      status: row.status,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      outputDirectory: row.outputDirectory,
      progress: DownloadProgress(
        transferredBytes: row.transferredBytes,
        totalBytes: row.totalBytes,
        speedBytesPerSecond: row.speedBytesPerSecond,
      ),
      fileName: row.fileName,
      failureMessage: row.failureMessage,
    );
  }

  DownloadTaskRowsCompanion _toCompanion(DownloadTask task) {
    return DownloadTaskRowsCompanion.insert(
      id: task.id,
      url: task.url,
      mediaType: task.mediaType,
      title: Value(task.title),
      status: task.status,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      outputDirectory: task.outputDirectory,
      transferredBytes: Value(task.progress.transferredBytes),
      totalBytes: Value(task.progress.totalBytes),
      speedBytesPerSecond: Value(task.progress.speedBytesPerSecond),
      fileName: Value(task.fileName),
      failureMessage: Value(task.failureMessage),
    );
  }
}