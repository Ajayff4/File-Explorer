import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:file_explorer/features/downloader/data/downloader_database.dart';
import 'package:file_explorer/features/explorer/data/platform/android_storage_platform.dart';
import 'package:file_explorer/features/history_backup/data/history_backup_constants.dart';
import 'package:file_explorer/shared/config/flavor_config.dart';
import 'package:file_explorer/shared/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Restores database snapshots from the public History folder when the local
/// databases are missing or empty. Must run before any database is opened
/// (i.e. first thing in `main()`). Never overwrites local user data and never
/// throws — a backup must never break startup.
Future<void> restoreHistoryBackup() async {
  try {
    final historyPath = await HistoryBackupService.resolveHistoryPath();
    if (historyPath == null) return;
    final docsPath = await HistoryBackupService.resolveDocsPath();
    final service = HistoryBackupService(
      docsPath: docsPath,
      historyPath: historyPath,
    );
    await service.importAppDatabase();
    if (enableDownloader) {
      await service.importDatabase(
        fileName: kHistoryBackupDownloaderFileName,
        schemaVersion: kDownloaderDatabaseSchemaVersion,
        openProbe: DownloaderDatabase.new,
      );
    }
  } catch (_) {
    // Ignore — starting fresh is always a valid fallback.
  }
}

/// Snapshots the app databases into `<primary volume>/File Explorer/.history`
/// and restores them on fresh installs.
///
/// Export uses SQLite `VACUUM INTO`, which produces a consistent snapshot of
/// a live database without closing it. Import is a plain file copy that must
/// happen before the database is first opened (see [restoreHistoryBackup]).
///
/// Safety rules:
/// - Export is skipped when the local database holds no user rows, so
///   deleting the History folder contents is a reliable "start fresh".
/// - Import never overwrites a local database that already holds user rows.
/// - Import is skipped when the snapshot schema is newer than the running
///   app (a downgrade), avoiding migration crashes.
///
/// "User rows" excludes derived/system tables (the search index is rebuilt
/// automatically, and defaults are written eagerly on first launch): those
/// must never block a restore, nor trigger a backup of an otherwise empty
/// database. See [appIgnoredTables].
class HistoryBackupService {
  HistoryBackupService({
    required this.docsPath,
    required this.historyPath,
  });

  final String docsPath;
  final String historyPath;

  /// Tables that never count as user data for backup guards.
  ///
  /// - `search_index_entry_rows` is derived and rebuilt automatically.
  /// - `setting_rows` gets default rows eagerly on first launch.
  /// - `recent_location_rows` accumulates automatically from mere browsing —
  ///   a few minutes on a fresh install must not veto restoring years of
  ///   real history. (The snapshot still *contains* recents; they are only
  ///   ignored by the guards.)
  static const Set<String> appIgnoredTables = {
    'search_index_entry_rows',
    'setting_rows',
    'recent_location_rows',
  };

  /// Resolves `<primary volume>/File Explorer/.history`, or `null` when public
  /// shared storage is unavailable (non-Android, or volumes unreadable).
  static Future<String?> resolveHistoryPath() async {
    try {
      if (!Platform.isAndroid) return null;
      try {
        final volumes =
            await const AndroidStoragePlatform().getStorageVolumes();
        if (volumes.isNotEmpty) {
          return p.join(
            volumes.first.path,
            'File Explorer',
            kHistoryBackupFolderName,
          );
        }
      } catch (_) {
        // Fall through to the well-known primary path.
      }
      return p.join(
        '/storage/emulated/0',
        'File Explorer',
        kHistoryBackupFolderName,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String> resolveDocsPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<DateTime?> exportAppDatabase(AppDatabase db) {
    return exportDatabase(
      db,
      fileName: kHistoryBackupAppFileName,
      schemaVersion: kAppDatabaseSchemaVersion,
      ignoredTables: appIgnoredTables,
    );
  }

  /// Snapshots [db] into the History folder. Returns the export time, or
  /// `null` when there was nothing worth backing up or the export failed.
  /// Tables in [ignoredTables] never count towards "worth backing up".
  Future<DateTime?> exportDatabase(
    GeneratedDatabase db, {
    required String fileName,
    required int schemaVersion,
    Set<String> ignoredTables = const {},
  }) async {
    try {
      if (!await hasUserData(db, ignoredTables: ignoredTables)) return null;
      await Directory(historyPath).create(recursive: true);
      final target = p.join(historyPath, fileName);
      // VACUUM INTO refuses to overwrite an existing file, so snapshot into
      // a temp file and rename over the target. A failed vacuum therefore
      // keeps the previous snapshot intact.
      final staging = '$target.tmp';
      try {
        await File(staging).delete();
      } catch (_) {}
      await db.customStatement(
        "VACUUM INTO '${staging.replaceAll("'", "''")}'",
      );
      await File(staging).rename(target);
      final now = DateTime.now();
      await _writeMetaEntry(fileName, schemaVersion, now);
      return now;
    } catch (_) {
      return null;
    }
  }

  Future<bool> importAppDatabase() {
    return importDatabase(
      fileName: kHistoryBackupAppFileName,
      schemaVersion: kAppDatabaseSchemaVersion,
      openProbe: AppDatabase.new,
      ignoredTables: appIgnoredTables,
    );
  }

  /// Copies a snapshot over the local database file when the local file is
  /// missing, zero-length, or holds no user rows (see [hasUserData]).
  /// Returns whether a restore happened.
  Future<bool> importDatabase({
    required String fileName,
    required int schemaVersion,
    required GeneratedDatabase Function(QueryExecutor) openProbe,
    Set<String> ignoredTables = const {},
  }) async {
    try {
      final backup = File(p.join(historyPath, fileName));
      if (!await backup.exists()) return false;
      final backupSchema = await _metaSchemaFor(fileName);
      if (backupSchema == null || backupSchema > schemaVersion) return false;
      final local = File(p.join(docsPath, fileName));
      if (await local.exists()) {
        if (await local.length() > 0) {
          // Only restore over a database without user data — local user data
          // always wins. `null` means the contents could not be assessed:
          // keep local.
          final userRows =
              await _countLocalUserRows(local, openProbe, ignoredTables);
          if (userRows == null || userRows > 0) return false;
        }
      } else {
        await Directory(docsPath).create(recursive: true);
      }
      // Drop stale journal sidecars so the copied snapshot opens cleanly.
      for (final suffix in ['-wal', '-shm', '-journal']) {
        final sidecar = File('${local.path}$suffix');
        if (await sidecar.exists()) {
          try {
            await sidecar.delete();
          } catch (_) {}
        }
      }
      await backup.copy(local.path);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Last successful export time recorded in the History folder, if any.
  Future<DateTime?> lastBackupTime() async {
    try {
      final meta = await _readMeta();
      final exportedAt = meta['exportedAt'];
      if (exportedAt is String) return DateTime.tryParse(exportedAt);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Whether [db] holds any user rows outside [ignoredTables].
  /// Unknown/unreadable tables count as user data (conservative: an
  /// unrecognized table must block destructive decisions).
  static Future<bool> hasUserData(
    GeneratedDatabase db, {
    Set<String> ignoredTables = const {},
  }) async {
    try {
      for (final table in await _userTables(db)) {
        if (ignoredTables.contains(table)) continue;
        try {
          if (await _countIn(db, table) > 0) return true;
        } catch (_) {
          // Unreadable table — treat as user data to stay conservative.
          return true;
        }
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  /// Whether the History folder holds a usable snapshot of [fileName] that
  /// the running app (at [schemaVersion]) could restore.
  Future<bool> hasRestorableBackup({
    required String fileName,
    required int schemaVersion,
  }) async {
    try {
      if (!await File(p.join(historyPath, fileName)).exists()) return false;
      final backupSchema = await _metaSchemaFor(fileName);
      return backupSchema != null && backupSchema <= schemaVersion;
    } catch (_) {
      return false;
    }
  }

  /// Export time of the current snapshot, if any.
  Future<DateTime?> backupExportedAt() async {
    final meta = await _readMeta();
    final exportedAt = meta['exportedAt'];
    if (exportedAt is String) return DateTime.tryParse(exportedAt);
    return null;
  }

  /// Remembers that the user dismissed the restore prompt for the current
  /// snapshot, so they are not nagged on every launch.
  Future<void> dismissRestorePrompt() async {
    try {
      final meta = await _readMeta();
      final exportedAt = meta['exportedAt'];
      if (exportedAt is String) {
        meta['restoreDismissedAt'] = exportedAt;
        await File(p.join(historyPath, kHistoryBackupMetaFileName))
            .writeAsString(jsonEncode(meta));
      }
    } catch (_) {}
  }

  /// Whether the current snapshot's restore prompt was already dismissed.
  /// A newer snapshot (later export) re-arms the prompt automatically.
  Future<bool> isRestoreDismissed() async {
    try {
      final meta = await _readMeta();
      final exportedAt = meta['exportedAt'];
      final dismissedAt = meta['restoreDismissedAt'];
      if (exportedAt is! String || dismissedAt is! String) return false;
      final exported = DateTime.tryParse(exportedAt);
      final dismissed = DateTime.tryParse(dismissedAt);
      if (exported == null || dismissed == null) return false;
      return !dismissed.isBefore(exported);
    } catch (_) {
      return false;
    }
  }
  static Future<List<String>> _userTables(GeneratedDatabase db) async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    return [for (final row in rows) row.read<String>('name')];
  }

  static Future<int> _countIn(GeneratedDatabase db, String table) async {
    final quoted = '"${table.replaceAll('"', '""')}"';
    final row =
        await db.customSelect('SELECT COUNT(*) AS c FROM $quoted').getSingle();
    return row.read<int>('c');
  }

  /// Total user rows in [file] outside [ignoredTables], or `null` when the
  /// contents cannot be assessed (then the caller must keep the local file).
  Future<int?> _countLocalUserRows(
    File file,
    GeneratedDatabase Function(QueryExecutor) openProbe,
    Set<String> ignoredTables,
  ) async {
    GeneratedDatabase? probe;
    try {
      probe = openProbe(NativeDatabase(file));
      var total = 0;
      var knownTables = 0;
      for (final table in await _userTables(probe)) {
        if (ignoredTables.contains(table)) continue;
        try {
          total += await _countIn(probe, table);
          knownTables++;
        } catch (_) {
          // Unreadable non-ignored table: contents suspicious, keep local.
          return null;
        }
      }
      if (knownTables == 0) return null;
      return total;
    } catch (_) {
      return null;
    } finally {
      try {
        await probe?.close();
      } catch (_) {}
    }
  }

  Future<Map<String, Object?>> _readMeta() async {
    try {
      final file = File(p.join(historyPath, kHistoryBackupMetaFileName));
      if (!await file.exists()) return {};
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return {};
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    } catch (_) {
      return {};
    }
  }

  Future<int?> _metaSchemaFor(String fileName) async {
    final meta = await _readMeta();
    final databases = meta['databases'];
    if (databases is Map) {
      final entry = databases[fileName];
      if (entry is Map && entry['schema'] is int) {
        return entry['schema'] as int;
      }
    }
    return null;
  }

  Future<void> _writeMetaEntry(
    String fileName,
    int schemaVersion,
    DateTime now,
  ) async {
    final meta = await _readMeta();
    final databases = <String, Object?>{};
    final existing = meta['databases'];
    if (existing is Map) {
      for (final entry in existing.entries) {
        if (entry.value is Map) {
          databases[entry.key.toString()] =
              Map<String, Object?>.from(entry.value as Map);
        }
      }
    }
    databases[fileName] = {'schema': schemaVersion};
    meta['version'] = 1;
    meta['exportedAt'] = now.toIso8601String();
    meta['databases'] = databases;
    await File(p.join(historyPath, kHistoryBackupMetaFileName))
        .writeAsString(jsonEncode(meta));
  }
}
