import 'package:drift/drift.dart';

/// No-op history backup for platforms without `dart:io` (e.g. web).
/// Same public API as the IO implementation so callers import
/// `history_backup_service.dart` unconditionally.
Future<void> restoreHistoryBackup() async {}

/// See the IO implementation. Never implemented here by design.
abstract interface class DownloaderBackupBackend {
  Future<DateTime?> exportBackend(HistoryBackupService service);
  Future<bool> importBackend(HistoryBackupService service);
  Future<void> closeBackend();
  Future<bool> hasLocalUserData();
  Future<bool> hasPendingRestore(HistoryBackupService service);
}

/// Always null on non-IO platforms.
DownloaderBackupBackend? downloaderBackupBackend;

class HistoryBackupService {
  HistoryBackupService({
    required this.docsPath,
    required this.historyPath,
  });

  final String docsPath;
  final String historyPath;

  static const Set<String> appIgnoredTables = {
    'search_index_entry_rows',
    'setting_rows',
  };

  static Future<String?> resolveHistoryPath() async => null;

  static Future<String> resolveDocsPath() async => '';

  static Future<bool> hasUserData(
    GeneratedDatabase db, {
    Set<String> ignoredTables = const {},
  }) async =>
      false;

  Future<DateTime?> exportAppDatabase(GeneratedDatabase db) async => null;

  Future<DateTime?> exportDatabase(
    GeneratedDatabase db, {
    required String fileName,
    required int schemaVersion,
    Set<String> ignoredTables = const {},
  }) async =>
      null;

  Future<bool> importAppDatabase() async => false;

  Future<bool> importDatabase({
    required String fileName,
    required int schemaVersion,
    required GeneratedDatabase Function(QueryExecutor) openProbe,
    Set<String> ignoredTables = const {},
  }) async =>
      false;

  Future<bool> hasRestorableBackup({
    required String fileName,
    required int schemaVersion,
  }) async =>
      false;

  Future<DateTime?> backupExportedAt() async => null;

  Future<DateTime?> lastBackupTime() async => null;

  Future<void> dismissRestorePrompt() async {}

  Future<bool> isRestoreDismissed() async => true;
}
