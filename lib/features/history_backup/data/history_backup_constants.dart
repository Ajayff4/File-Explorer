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
///
/// (The downloader snapshot filename lives in the downloader feature's
/// `downloader_history_backup.dart` — shared code must not name it, so the
/// `standard` binary keeps zero downloader traces.)
const String kHistoryBackupAppFileName = 'file_explorer.sqlite';

/// Sidecar in the backup folder describing the snapshots.
const String kHistoryBackupMetaFileName = 'history_meta.json';
