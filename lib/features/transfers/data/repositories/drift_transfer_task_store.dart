import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_task_store.dart';
import 'package:file_explorer/shared/database/app_database.dart';

class DriftTransferTaskStore implements TransferTaskStore {
  const DriftTransferTaskStore(this._database);

  final AppDatabase _database;

  @override
  Future<List<TransferTask>> loadTasks() async {
    final rows = await (_database.select(_database.transferTaskRows)
          ..orderBy([
            (table) => OrderingTerm.desc(table.updatedAt),
          ]))
        .get();
    return rows.map(_toTask).toList();
  }

  @override
  Future<void> saveTask(TransferTask task) {
    return _database.into(_database.transferTaskRows).insertOnConflictUpdate(
          _toCompanion(task),
        );
  }

  @override
  Future<void> deleteTasks(List<String> taskIds) async {
    if (taskIds.isEmpty) {
      return;
    }
    await (_database.delete(_database.transferTaskRows)
          ..where((table) => table.id.isIn(taskIds)))
        .go();
  }

  TransferTask _toTask(TransferTaskRow row) {
    final decodedPaths = jsonDecode(row.sourcePathsJson);
    final sourcePaths = decodedPaths is List
        ? decodedPaths.whereType<String>().toList(growable: false)
        : const <String>[];

    return TransferTask(
      id: row.id,
      operation: row.operation,
      sourcePaths: sourcePaths,
      displayName: row.displayName,
      status: row.status,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      destinationPath: row.destinationPath,
      progress: TransferProgress(
        transferredBytes: row.transferredBytes,
        totalBytes: row.totalBytes,
        currentItemPath: row.currentItemPath,
      ),
      conflictPolicy: row.conflictPolicy,
      failureMessage: row.failureMessage,
      failureCode: row.failureCode,
    );
  }

  TransferTaskRowsCompanion _toCompanion(TransferTask task) {
    return TransferTaskRowsCompanion.insert(
      id: task.id,
      operation: task.operation,
      sourcePathsJson: jsonEncode(task.sourcePaths),
      displayName: task.displayName,
      status: task.status,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      destinationPath: Value(task.destinationPath),
      transferredBytes: Value(task.progress.transferredBytes),
      totalBytes: Value(task.progress.totalBytes),
      currentItemPath: Value(task.progress.currentItemPath),
      conflictPolicy: task.conflictPolicy,
      failureMessage: Value(task.failureMessage),
      failureCode: Value(task.failureCode),
    );
  }
}
