import 'package:file_explorer/features/settings/domain/entities/app_settings.dart';
import 'package:file_explorer/features/settings/domain/repositories/settings_store.dart';
import 'package:file_explorer/shared/database/app_database.dart';

class DriftSettingsStore implements SettingsStore {
  const DriftSettingsStore(this._database);

  final AppDatabase _database;

  @override
  Future<AppSettings> loadSettings() async {
    final rows = await _database.select(_database.settingRows).get();
    final values = {
      for (final row in rows)
        if (_keyFor(row.key) != null) _keyFor(row.key)!: row.value == 'true',
    };
    return _toSettings(values);
  }

  @override
  Future<void> saveBool(SettingKey key, bool value) {
    return _database.into(_database.settingRows).insertOnConflictUpdate(
          SettingRowsCompanion.insert(
            key: key.storageKey,
            value: value.toString(),
            updatedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> resetSettings() {
    return _database.delete(_database.settingRows).go();
  }

  SettingKey? _keyFor(String storageKey) {
    for (final key in SettingKey.values) {
      if (key.storageKey == storageKey) {
        return key;
      }
    }
    return null;
  }

  AppSettings _toSettings(Map<SettingKey, bool> values) {
    const defaults = AppSettings();
    return defaults.copyWith(
      showHiddenFiles:
          values[SettingKey.showHiddenFiles] ?? defaults.showHiddenFiles,
      confirmDestructiveActions: values[SettingKey.confirmDestructiveActions] ??
          defaults.confirmDestructiveActions,
      showFoldersOnlyInHistory: values[SettingKey.showFoldersOnlyInHistory] ??
          defaults.showFoldersOnlyInHistory,
      useIndexedSearch:
          values[SettingKey.useIndexedSearch] ?? defaults.useIndexedSearch,
      showTransferStation: values[SettingKey.showTransferStation] ??
          defaults.showTransferStation,
    );
  }
}
