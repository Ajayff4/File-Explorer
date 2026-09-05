import 'package:file_explorer/features/downloader/data/downloader_database.dart';
import 'package:file_explorer/features/downloader/data/downloader_database_provider.dart';
import 'package:file_explorer/features/history_backup/data/history_backup_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Snapshot filename for the feature-local downloader database.
/// Owned here (not in shared constants) so `standard` builds keep zero
/// downloader traces, including plain strings.
const String kDownloaderBackupFileName = 'downloader.sqlite';

/// Downloader side of the history backup. Registered into
/// [downloaderBackupBackend] from `downloaderDatabaseProvider`'s initializer,
/// which only runs when the feature is compiled in — shared backup code
/// never references downloader types directly.
class DownloaderHistoryBackup implements DownloaderBackupBackend {
  DownloaderHistoryBackup(this._ref);

  final Ref _ref;

  DownloaderDatabase _db() => _ref.read(downloaderDatabaseProvider);

  @override
  Future<DateTime?> exportBackend(HistoryBackupService service) {
    return service.exportDatabase(
      _db(),
      fileName: kDownloaderBackupFileName,
      schemaVersion: kDownloaderDatabaseSchemaVersion,
    );
  }

  @override
  Future<bool> importBackend(HistoryBackupService service) {
    return service.importDatabase(
      fileName: kDownloaderBackupFileName,
      schemaVersion: kDownloaderDatabaseSchemaVersion,
      openProbe: DownloaderDatabase.new,
    );
  }

  @override
  Future<void> closeBackend() async {
    try {
      await _ref.read(downloaderDatabaseProvider).close();
    } catch (_) {}
  }

  @override
  Future<bool> hasLocalUserData() async {
    try {
      return HistoryBackupService.hasUserData(_db());
    } catch (_) {
      return true;
    }
  }

  @override
  Future<bool> hasPendingRestore(HistoryBackupService service) {
    return service.hasRestorableBackup(
      fileName: kDownloaderBackupFileName,
      schemaVersion: kDownloaderDatabaseSchemaVersion,
    );
  }
}

/// Called from `downloaderDatabaseProvider`'s initializer. Never called from
/// shared code, so `standard` builds never link this file.
void registerDownloaderBackup(Ref ref) {
  downloaderBackupBackend ??= DownloaderHistoryBackup(ref);
}
