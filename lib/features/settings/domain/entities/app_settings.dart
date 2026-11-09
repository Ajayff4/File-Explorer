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
  mint,
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
    this.homeFolderPath,
  });

  static const Object _unsetHomeFolderPath = Object();

  final bool showHiddenFiles;
  final bool confirmDestructiveActions;
  final bool showFoldersOnlyInHistory;
  final bool useIndexedSearch;
  final bool showTransferStation;

  final AppThemeMode themeMode;
  final AppThemeAccent themeAccent;

  /// Folder Explorer opens on launch. `null` uses the primary storage root.
  final String? homeFolderPath;

  AppSettings copyWith({
    bool? showHiddenFiles,
    bool? confirmDestructiveActions,
    bool? showFoldersOnlyInHistory,
    bool? useIndexedSearch,
    bool? showTransferStation,
    AppThemeMode? themeMode,
    AppThemeAccent? themeAccent,
    Object? homeFolderPath = _unsetHomeFolderPath,
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
      homeFolderPath: identical(homeFolderPath, _unsetHomeFolderPath)
          ? this.homeFolderPath
          : homeFolderPath as String?,
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
  themeAccent('theme_accent'),
  homeFolder('home_folder');

  const SettingKey(this.storageKey);

  final String storageKey;
}
