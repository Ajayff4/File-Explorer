/// Theme brightness selection. Mirrors `ThemeMode` without pulling Flutter
/// into the settings domain.
enum AppThemeMode {
  system,
  light,
  dark,
}

/// Accent color for the app-wide theme. Each accent ships a dark ("black-x")
/// and a light ("white-x") variant; the purple accent is the default.
enum AppThemeAccent {
  purple,
  green,
  pink,
  red,
  royalBlue,
}

class AppSettings {
  const AppSettings({
    this.showHiddenFiles = false,
    this.confirmDestructiveActions = true,
    this.showFoldersOnlyInHistory = true,
    this.useIndexedSearch = true,
    this.showTransferStation = true,
    this.themeMode = AppThemeMode.dark,
    this.themeAccent = AppThemeAccent.purple,
  });

  final bool showHiddenFiles;
  final bool confirmDestructiveActions;
  final bool showFoldersOnlyInHistory;
  final bool useIndexedSearch;
  final bool showTransferStation;

  final AppThemeMode themeMode;
  final AppThemeAccent themeAccent;

  AppSettings copyWith({
    bool? showHiddenFiles,
    bool? confirmDestructiveActions,
    bool? showFoldersOnlyInHistory,
    bool? useIndexedSearch,
    bool? showTransferStation,
    AppThemeMode? themeMode,
    AppThemeAccent? themeAccent,
  }) {
    return AppSettings(
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      confirmDestructiveActions:
          confirmDestructiveActions ?? this.confirmDestructiveActions,
      showFoldersOnlyInHistory:
          showFoldersOnlyInHistory ?? this.showFoldersOnlyInHistory,
      useIndexedSearch: useIndexedSearch ?? this.useIndexedSearch,
      showTransferStation: showTransferStation ?? this.showTransferStation,
      themeMode: themeMode ?? this.themeMode,
      themeAccent: themeAccent ?? this.themeAccent,
    );
  }
}

enum SettingKey {
  showHiddenFiles('show_hidden_files'),
  confirmDestructiveActions('confirm_destructive_actions'),
  showFoldersOnlyInHistory('show_folders_only_in_history'),
  useIndexedSearch('use_indexed_search'),
  showTransferStation('show_transfer_station'),
  themeMode('theme_mode'),
  themeAccent('theme_accent');

  const SettingKey(this.storageKey);

  final String storageKey;
}
