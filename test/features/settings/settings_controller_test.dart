import 'package:file_explorer/features/settings/data/repositories/in_memory_settings_store.dart';
import 'package:file_explorer/features/settings/domain/entities/app_settings.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads default settings', () async {
    final controller = SettingsController(InMemorySettingsStore());

    await controller.loadSettings();

    expect(controller.state.settings.showHiddenFiles, isFalse);
    expect(controller.state.settings.confirmDestructiveActions, isTrue);
    expect(controller.state.settings.useIndexedSearch, isTrue);
  });

  test('updates and persists setting values', () async {
    final store = InMemorySettingsStore();
    final controller = SettingsController(store);

    await controller.setBool(SettingKey.showHiddenFiles, true);
    await controller.setBool(SettingKey.useIndexedSearch, false);

    final reloadedController = SettingsController(store);
    await reloadedController.loadSettings();

    expect(reloadedController.state.settings.showHiddenFiles, isTrue);
    expect(reloadedController.state.settings.useIndexedSearch, isFalse);
  });

  test('resets settings to defaults', () async {
    final controller = SettingsController(InMemorySettingsStore());

    await controller.setBool(SettingKey.showHiddenFiles, true);
    await controller.resetSettings();

    expect(controller.state.settings, isA<AppSettings>());
    expect(controller.state.settings.showHiddenFiles, isFalse);
  });

  test('defaults to dark purple theme', () async {
    final controller = SettingsController(InMemorySettingsStore());
    await controller.loadSettings();

    expect(controller.state.settings.themeMode, AppThemeMode.dark);
    expect(controller.state.settings.themeAccent, AppThemeAccent.purple);
  });

  test('updates and persists theme mode and accent', () async {
    final store = InMemorySettingsStore();
    final controller = SettingsController(store);

    await controller.setThemeMode(AppThemeMode.light);
    await controller.setThemeAccent(AppThemeAccent.royalBlue);

    final reloadedController = SettingsController(store);
    await reloadedController.loadSettings();

    expect(reloadedController.state.settings.themeMode, AppThemeMode.light);
    expect(
      reloadedController.state.settings.themeAccent,
      AppThemeAccent.royalBlue,
    );
  });
}
