import 'package:file_explorer/features/settings/domain/entities/app_settings.dart';

abstract interface class SettingsStore {
  Future<AppSettings> loadSettings();
  Future<void> saveBool(SettingKey key, bool value);
  Future<void> resetSettings();
}
