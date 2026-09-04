import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/history_backup/data/history_backup_constants.dart';
import 'package:file_explorer/features/history_backup/data/history_backup_service.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/shared/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temp;
  late Directory docs;
  late Directory history;
  late HistoryBackupService service;
  final openDatabases = <AppDatabase>[];

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('history_backup_test');
    docs = Directory('${temp.path}/docs')..createSync(recursive: true);
    history = Directory('${temp.path}/history');
    service = HistoryBackupService(
      docsPath: docs.path,
      historyPath: history.path,
    );
  });

  tearDown(() async {
    for (final db in openDatabases) {
      try {
        await db.close();
      } catch (_) {}
    }
    openDatabases.clear();
    try {
      await temp.delete(recursive: true);
    } catch (_) {}
  });

  AppDatabase openDb(String dir) {
    final db = AppDatabase(
      NativeDatabase(File('$dir/$kHistoryBackupAppFileName')),
    );
    openDatabases.add(db);
    return db;
  }

  Future<void> createSchema(AppDatabase db) async {
    await Migrator(db).createAll();
  }

  Future<void> seedTransfer(AppDatabase db, {String id = 't1'}) async {
    await db.into(db.transferTaskRows).insert(
          TransferTaskRowsCompanion.insert(
            id: id,
            operation: TransferOperation.copy,
            sourcePathsJson: '["/a"]',
            displayName: 'copy a',
            status: TransferTaskStatus.completed,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 2),
            conflictPolicy: ConflictPolicy.ask,
          ),
        );
  }

  Future<void> seedDerivedOnly(AppDatabase db) async {
    // What a fresh launch writes on its own: default settings, a rebuilt
    // search index, and auto-recorded recents. None of it is user history.
    await db.into(db.settingRows).insert(
          SettingRowsCompanion.insert(
            key: 'theme_mode',
            value: 'system',
            updatedAt: DateTime(2026, 1, 1),
          ),
        );
    await db.into(db.searchIndexEntryRows).insert(
          SearchIndexEntryRowsCompanion.insert(
            path: '/storage/emulated/0/DCIM',
            rootPath: '/storage/emulated/0',
            parentPath: '/storage/emulated/0',
            name: 'DCIM',
            type: FileSystemEntryType.folder,
            modifiedAt: DateTime(2026, 1, 1),
            depth: 1,
            indexedAt: DateTime(2026, 1, 1),
          ),
        );
    await db.into(db.recentLocationRows).insert(
          RecentLocationRowsCompanion.insert(
            path: '/storage/emulated/0/DCIM',
            label: 'DCIM',
            openedAt: DateTime(2026, 1, 1),
          ),
        );
  }

  Future<int> transferCount(AppDatabase db) async {
    final rows = await db.select(db.transferTaskRows).get();
    return rows.length;
  }

  test('export skips an empty database and writes nothing', () async {
    final db = openDb(docs.path);
    await createSchema(db);

    final result = await service.exportAppDatabase(db);

    expect(result, isNull);
    expect(await history.exists(), isFalse);
  });

  test('export writes a snapshot plus meta, and reports backup time',
      () async {
    final db = openDb(docs.path);
    await createSchema(db);
    await seedTransfer(db);

    final result = await service.exportAppDatabase(db);

    expect(result, isNotNull);
    expect(
      await File('${history.path}/$kHistoryBackupAppFileName').exists(),
      isTrue,
    );
    final metaFile = File('${history.path}/$kHistoryBackupMetaFileName');
    expect(await metaFile.exists(), isTrue);
    final meta = jsonDecode(await metaFile.readAsString()) as Map;
    expect(
      (meta['databases'] as Map)[kHistoryBackupAppFileName]['schema'],
      kAppDatabaseSchemaVersion,
    );
    expect(await service.lastBackupTime(), isNotNull);
  });

  test('import restores a snapshot into an empty docs dir', () async {
    final source = openDb(docs.path);
    await createSchema(source);
    await seedTransfer(source);
    await service.exportAppDatabase(source);
    for (final db in openDatabases) {
      await db.close();
    }
    openDatabases.clear();

    final freshDocs = Directory('${temp.path}/fresh')..createSync();
    final fresh = HistoryBackupService(
      docsPath: freshDocs.path,
      historyPath: history.path,
    );
    expect(await fresh.importAppDatabase(), isTrue);

    final restored = openDb(freshDocs.path);
    expect(await transferCount(restored), 1);
  });

  test('import never overwrites local user data', () async {
    // Local install already has its own history.
    final local = openDb(docs.path);
    await createSchema(local);
    await seedTransfer(local, id: 'local');
    // Close before opening another database: only one opener exists at a
    // time (same discipline as production, where the import probe runs
    // before startup and exports use the single provider instance).
    await local.close();
    openDatabases.remove(local);

    // A backup from elsewhere exists.
    final otherDir = Directory('${temp.path}/other')..createSync();
    final other = openDb(otherDir.path);
    await createSchema(other);
    await seedTransfer(other, id: 'backup');
    final backupService = HistoryBackupService(
      docsPath: otherDir.path,
      historyPath: history.path,
    );
    await backupService.exportAppDatabase(other);
    await other.close();
    openDatabases.remove(other);

    expect(await service.importAppDatabase(), isFalse);
    final verify = openDb(docs.path);
    expect(await transferCount(verify), 1);
    final rows = await verify.select(verify.transferTaskRows).get();
    expect(rows.single.id, 'local');
  });

  test('import refuses snapshots from a newer schema', () async {
    final source = openDb(docs.path);
    await createSchema(source);
    await seedTransfer(source);
    await service.exportAppDatabase(source);

    final metaFile = File('${history.path}/$kHistoryBackupMetaFileName');
    final meta = jsonDecode(await metaFile.readAsString()) as Map;
    (meta['databases'] as Map)[kHistoryBackupAppFileName]['schema'] =
        kAppDatabaseSchemaVersion + 1;
    await metaFile.writeAsString(jsonEncode(meta));
    for (final db in openDatabases) {
      await db.close();
    }
    openDatabases.clear();

    final freshDocs = Directory('${temp.path}/fresh')..createSync();
    final fresh = HistoryBackupService(
      docsPath: freshDocs.path,
      historyPath: history.path,
    );
    expect(await fresh.importAppDatabase(), isFalse);
    expect(
      await File('${freshDocs.path}/$kHistoryBackupAppFileName').exists(),
      isFalse,
    );
  });

  test('derived rows alone never trigger an export', () async {
    final db = openDb(docs.path);
    await createSchema(db);
    await seedDerivedOnly(db);

    expect(await service.exportAppDatabase(db), isNull);
    expect(await history.exists(), isFalse);
  });

  test('import restores over derived-only local data', () async {
    final source = openDb(docs.path);
    await createSchema(source);
    await seedTransfer(source);
    await service.exportAppDatabase(source);
    await source.close();
    openDatabases.remove(source);

    // Fresh install state: settings defaults + rebuilt index, no history.
    final freshDocs = Directory('${temp.path}/fresh')..createSync();
    final fresh = HistoryBackupService(
      docsPath: freshDocs.path,
      historyPath: history.path,
    );
    final local = openDb(freshDocs.path);
    await createSchema(local);
    await seedDerivedOnly(local);
    await local.close();
    openDatabases.remove(local);

    expect(await fresh.importAppDatabase(), isTrue);
    final restored = openDb(freshDocs.path);
    expect(await transferCount(restored), 1);
  });

  test('re-export overwrites a previous snapshot', () async {
    // Regression test: VACUUM INTO refuses to overwrite, so exports must
    // stage into a temp file first. The second export has to succeed and
    // carry the newer data.
    final db = openDb(docs.path);
    await createSchema(db);
    await seedTransfer(db, id: 't1');
    expect(await service.exportAppDatabase(db), isNotNull);
    await seedTransfer(db, id: 't2');
    expect(await service.exportAppDatabase(db), isNotNull);
    await db.close();
    openDatabases.remove(db);

    final freshDocs = Directory('${temp.path}/fresh')..createSync();
    final fresh = HistoryBackupService(
      docsPath: freshDocs.path,
      historyPath: history.path,
    );
    expect(await fresh.importAppDatabase(), isTrue);
    final restored = openDb(freshDocs.path);
    expect(await transferCount(restored), 2);
  });

  test('restorable backup detection and dismissal', () async {
    expect(
      await service.hasRestorableBackup(
        fileName: kHistoryBackupAppFileName,
        schemaVersion: kAppDatabaseSchemaVersion,
      ),
      isFalse,
    );

    final source = openDb(docs.path);
    await createSchema(source);
    await seedTransfer(source);
    await service.exportAppDatabase(source);

    expect(
      await service.hasRestorableBackup(
        fileName: kHistoryBackupAppFileName,
        schemaVersion: kAppDatabaseSchemaVersion,
      ),
      isTrue,
    );
    expect(await service.isRestoreDismissed(), isFalse);
    await service.dismissRestorePrompt();
    expect(await service.isRestoreDismissed(), isTrue);
  });
}
