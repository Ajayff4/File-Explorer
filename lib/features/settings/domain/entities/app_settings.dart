class AppSettings {
  const AppSettings({
    this.showHiddenFiles = false,
    this.confirmDestructiveActions = true,
    this.showFoldersOnlyInHistory = true,
    this.useIndexedSearch = true,
    this.showTransferStation = true,
  });

  final bool showHiddenFiles;
  final bool confirmDestructiveActions;
  final bool showFoldersOnlyInHistory;
  final bool useIndexedSearch;
  final bool showTransferStation;

  AppSettings copyWith({
    bool? showHiddenFiles,
    bool? confirmDestructiveActions,
    bool? showFoldersOnlyInHistory,
    bool? useIndexedSearch,
    bool? showTransferStation,
  }) {
    return AppSettings(
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      confirmDestructiveActions:
          confirmDestructiveActions ?? this.confirmDestructiveActions,
      showFoldersOnlyInHistory:
          showFoldersOnlyInHistory ?? this.showFoldersOnlyInHistory,
      useIndexedSearch: useIndexedSearch ?? this.useIndexedSearch,
      showTransferStation: showTransferStation ?? this.showTransferStation,
    );
  }
}

enum SettingKey {
  showHiddenFiles('show_hidden_files'),
  confirmDestructiveActions('confirm_destructive_actions'),
  showFoldersOnlyInHistory('show_folders_only_in_history'),
  useIndexedSearch('use_indexed_search'),
  showTransferStation('show_transfer_station');

  const SettingKey(this.storageKey);

  final String storageKey;
}
