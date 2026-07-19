import 'package:file_explorer/features/settings/domain/entities/app_settings.dart';
import 'package:file_explorer/features/settings/domain/repositories/settings_store.dart';

class InMemorySettingsStore implements SettingsStore {
  final Map<SettingKey, bool> _values = {};

  @override
  Future<AppSettings> loadSettings() async {
    return _toSettings(_values);
  }

  @override
  Future<void> saveBool(SettingKey key, bool value) async {
    _values[key] = value;
  }

  @override
  Future<void> resetSettings() async {
    _values.clear();
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
