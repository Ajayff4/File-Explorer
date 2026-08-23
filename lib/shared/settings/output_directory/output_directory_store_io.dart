import 'package:file_explorer/shared/database/app_database.dart';
import 'package:file_explorer/shared/database/app_database_provider.dart';
import 'package:file_explorer/shared/settings/output_directory/output_directory_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persists a single output-directory key in the shared [SettingRows] table.
class DriftOutputDirectoryStore implements OutputDirectoryStore {
  const DriftOutputDirectoryStore(this._database, this._key);

  final AppDatabase _database;
  final String _key;

  @override
  Future<String> load() async {
    final rows = await _database.select(_database.settingRows).get();
    final values = {
      for (final row in rows) row.key: row.value,
    };
    return values[_key] ?? '';
  }

  @override
  Future<void> save(String directory) async {
    final now = DateTime.now();
    await _database.into(_database.settingRows).insertOnConflictUpdate(
          SettingRowsCompanion.insert(
            key: _key,
            value: directory,
            updatedAt: now,
          ),
        );
  }
}

OutputDirectoryStore createOutputDirectoryStore(Ref ref, String key) {
  return DriftOutputDirectoryStore(ref.watch(appDatabaseProvider), key);
}
