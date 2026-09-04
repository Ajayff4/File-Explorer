/// Shared constants for the history backup feature.
///
/// The backup snapshots the app databases as plain SQLite files inside a
/// hidden public folder (`<primary volume>/File Explorer/.history`) that
/// survives app uninstalls, so a fresh install can restore history
/// automatically. The dot prefix keeps it out of sight for non-technical
/// users (visible with "show hidden files"). Deleting the folder contents
/// means "start fresh" — there is simply nothing to restore.
///
/// This file is pure Dart (no `dart:io`) so it can be imported anywhere,
// including the web build.
library;

/// Name of the hidden public folder (under `<primary volume>/File Explorer`).
const String kHistoryBackupFolderName = '.history';

/// Snapshot file for the shared [AppDatabase].
const String kHistoryBackupAppFileName = 'file_explorer.sqlite';

/// Snapshot file for the feature-local downloader database (universal only).
const String kHistoryBackupDownloaderFileName = 'downloader.sqlite';

/// Sidecar in the backup folder describing the snapshots.
const String kHistoryBackupMetaFileName = 'history_meta.json';
