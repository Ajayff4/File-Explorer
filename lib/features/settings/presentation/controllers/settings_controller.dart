import 'dart:async';

import 'package:file_explorer/features/settings/data/repositories/settings_store_provider.dart';
import 'package:file_explorer/features/settings/domain/entities/app_settings.dart';
import 'package:file_explorer/features/settings/domain/repositories/settings_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final controller = SettingsController(ref.read(settingsStoreProvider));
  unawaited(controller.loadSettings());
  return controller;
});

class SettingsState {
  const SettingsState({
    this.settings = const AppSettings(),
    this.isLoading = false,
  });

  final AppSettings settings;
  final bool isLoading;

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._store) : super(const SettingsState());

  final SettingsStore _store;

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);
    final settings = await _store.loadSettings();
    if (!mounted) {
      return;
    }
    state = state.copyWith(settings: settings, isLoading: false);
  }

  Future<void> setBool(SettingKey key, bool value) async {
    await _store.saveBool(key, value);
    if (!mounted) {
      return;
    }
    state = state.copyWith(settings: _copyWith(key, value));
  }

  Future<void> resetSettings() async {
    await _store.resetSettings();
    if (!mounted) {
      return;
    }
    state = state.copyWith(settings: const AppSettings());
  }

  AppSettings _copyWith(SettingKey key, bool value) {
    final current = state.settings;
    return switch (key) {
      SettingKey.showHiddenFiles => current.copyWith(showHiddenFiles: value),
      SettingKey.confirmDestructiveActions =>
        current.copyWith(confirmDestructiveActions: value),
      SettingKey.showFoldersOnlyInHistory =>
        current.copyWith(showFoldersOnlyInHistory: value),
      SettingKey.useIndexedSearch => current.copyWith(useIndexedSearch: value),
      SettingKey.showTransferStation =>
        current.copyWith(showTransferStation: value),
    };
  }
}
