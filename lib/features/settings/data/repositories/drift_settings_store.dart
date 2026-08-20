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
      for (final row in rows) row.key: row.value,
    };

    const defaults = AppSettings();

    AppThemeMode readThemeMode() {
      final raw = values[SettingKey.themeMode.storageKey];
      for (final mode in AppThemeMode.values) {
        if (mode.name == raw) {
          return mode;
        }
      }
      return defaults.themeMode;
    }

    AppThemeAccent readThemeAccent() {
      final raw = values[SettingKey.themeAccent.storageKey];
      for (final accent in AppThemeAccent.values) {
        if (accent.name == raw) {
          return accent;
        }
      }
      return defaults.themeAccent;
    }

    return defaults.copyWith(
      showHiddenFiles: values[SettingKey.showHiddenFiles.storageKey] == 'true',
      confirmDestructiveActions:
          values[SettingKey.confirmDestructiveActions.storageKey] == 'true',
      showFoldersOnlyInHistory:
          values[SettingKey.showFoldersOnlyInHistory.storageKey] == 'true',
      useIndexedSearch:
          values[SettingKey.useIndexedSearch.storageKey] == 'true',
      showTransferStation:
          values[SettingKey.showTransferStation.storageKey] == 'true',
      themeMode: readThemeMode(),
      themeAccent: readThemeAccent(),
    );
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
  Future<void> saveString(SettingKey key, String value) {
    return _database.into(_database.settingRows).insertOnConflictUpdate(
          SettingRowsCompanion.insert(
            key: key.storageKey,
            value: value,
            updatedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> resetSettings() {
    return _database.delete(_database.settingRows).go();
  }
}
