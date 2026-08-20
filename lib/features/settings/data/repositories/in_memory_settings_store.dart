import 'package:file_explorer/features/settings/domain/entities/app_settings.dart';
import 'package:file_explorer/features/settings/domain/repositories/settings_store.dart';

class InMemorySettingsStore implements SettingsStore {
  final Map<SettingKey, bool> _boolValues = {};
  final Map<SettingKey, String> _stringValues = {};

  @override
  Future<AppSettings> loadSettings() async {
    return _toSettings(_boolValues, _stringValues);
  }

  @override
  Future<void> saveBool(SettingKey key, bool value) async {
    _boolValues[key] = value;
  }

  @override
  Future<void> saveString(SettingKey key, String value) async {
    _stringValues[key] = value;
  }

  @override
  Future<void> resetSettings() async {
    _boolValues.clear();
    _stringValues.clear();
  }

  AppSettings _toSettings(
    Map<SettingKey, bool> boolValues,
    Map<SettingKey, String> stringValues,
  ) {
    const defaults = AppSettings();

    AppThemeMode readThemeMode() {
      final raw = stringValues[SettingKey.themeMode];
      for (final mode in AppThemeMode.values) {
        if (mode.name == raw) {
          return mode;
        }
      }
      return defaults.themeMode;
    }

    AppThemeAccent readThemeAccent() {
      final raw = stringValues[SettingKey.themeAccent];
      for (final accent in AppThemeAccent.values) {
        if (accent.name == raw) {
          return accent;
        }
      }
      return defaults.themeAccent;
    }

    return defaults.copyWith(
      showHiddenFiles:
          boolValues[SettingKey.showHiddenFiles] ?? defaults.showHiddenFiles,
      confirmDestructiveActions:
          boolValues[SettingKey.confirmDestructiveActions] ??
              defaults.confirmDestructiveActions,
      showFoldersOnlyInHistory:
          boolValues[SettingKey.showFoldersOnlyInHistory] ??
              defaults.showFoldersOnlyInHistory,
      useIndexedSearch:
          boolValues[SettingKey.useIndexedSearch] ?? defaults.useIndexedSearch,
      showTransferStation: boolValues[SettingKey.showTransferStation] ??
          defaults.showTransferStation,
      themeMode: readThemeMode(),
      themeAccent: readThemeAccent(),
    );
  }
}
