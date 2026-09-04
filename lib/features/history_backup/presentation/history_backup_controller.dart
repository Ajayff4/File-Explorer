import 'dart:async';

import 'package:file_explorer/features/downloader/data/downloader_database.dart';
import 'package:file_explorer/features/downloader/data/downloader_database_provider.dart';
import 'package:file_explorer/features/history_backup/data/history_backup_constants.dart';
import 'package:file_explorer/features/history_backup/data/history_backup_service.dart';
import 'package:file_explorer/shared/config/flavor_config.dart';
import 'package:file_explorer/shared/database/app_database.dart';
import 'package:file_explorer/shared/database/app_database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final historyBackupControllerProvider =
    NotifierProvider<HistoryBackupController, HistoryBackupState>(
  HistoryBackupController.new,
);

class HistoryBackupState {
  const HistoryBackupState({
    this.isWorking = false,
    this.lastBackupAt,
    this.unavailable = false,
    this.lastResult,
  });

  final bool isWorking;
  final DateTime? lastBackupAt;

  /// True when public shared storage cannot be used on this device.
  final bool unavailable;

  /// Outcome of the most recent manual export, if any.
  final bool? lastResult;

  HistoryBackupState copyWith({
    bool? isWorking,
    DateTime? lastBackupAt,
    bool? unavailable,
    bool? lastResult,
  }) {
    return HistoryBackupState(
      isWorking: isWorking ?? this.isWorking,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      unavailable: unavailable ?? this.unavailable,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

/// Drives automatic + manual history backups.
///
/// Automatic exports run at startup and when the app goes to the background
/// (wired in `WindowHost`); restores run before startup in `main()` via
/// [restoreHistoryBackup].
class HistoryBackupController extends Notifier<HistoryBackupState> {
  DateTime? _lastAutoAttempt;

  @override
  HistoryBackupState build() {
    Future.microtask(() => refreshStatus());
    return const HistoryBackupState();
  }

  Future<HistoryBackupService?> _service() async {
    final historyPath = await HistoryBackupService.resolveHistoryPath();
    if (historyPath == null) return null;
    final docsPath = await HistoryBackupService.resolveDocsPath();
    return HistoryBackupService(
      docsPath: docsPath,
      historyPath: historyPath,
    );
  }

  Future<void> refreshStatus() async {
    try {
      final service = await _service();
      if (!ref.mounted) return;
      if (service == null) {
        state = state.copyWith(unavailable: true);
        return;
      }
      state = state.copyWith(
        unavailable: false,
        lastBackupAt: await service.lastBackupTime(),
      );
    } catch (_) {
      // Status is best-effort; the card shows "not backed up yet".
    }
  }

  /// Manual export. Returns true when a fresh snapshot was written.
  Future<bool> exportNow() async {
    if (state.isWorking) return false;
    state = state.copyWith(isWorking: true, lastResult: null);
    try {
      final service = await _service();
      if (!ref.mounted) return false;
      if (service == null) {
        state = state.copyWith(isWorking: false, unavailable: true);
        return false;
      }
      final appAt =
          await service.exportAppDatabase(ref.read(appDatabaseProvider));
      await _exportDownloader(service);
      if (!ref.mounted) return false;
      final ok = appAt != null;
      state = state.copyWith(
        isWorking: false,
        unavailable: false,
        lastBackupAt: await service.lastBackupTime(),
        lastResult: ok,
      );
      return ok;
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(isWorking: false, lastResult: false);
      }
      return false;
    }
  }

  /// Silent background export, throttled so rapid background/foreground
  /// cycles don't rewrite snapshots constantly.
  Future<void> exportIfDue({
    Duration minInterval = const Duration(minutes: 2),
  }) async {
    if (state.isWorking) return;
    final now = DateTime.now();
    if (_lastAutoAttempt != null &&
        now.difference(_lastAutoAttempt!) < minInterval) {
      return;
    }
    _lastAutoAttempt = now;
    state = state.copyWith(isWorking: true);
    try {
      final service = await _service();
      if (!ref.mounted) return;
      if (service == null) {
        state = state.copyWith(isWorking: false, unavailable: true);
        return;
      }
      await service.exportAppDatabase(ref.read(appDatabaseProvider));
      await _exportDownloader(service);
      if (!ref.mounted) return;
      state = state.copyWith(
        isWorking: false,
        unavailable: false,
        lastBackupAt: await service.lastBackupTime(),
      );
    } catch (_) {
      if (ref.mounted) state = state.copyWith(isWorking: false);
    }
  }

  Future<void> _exportDownloader(HistoryBackupService service) async {
    // The whole downloader graph (including these references) is tree-shaken
    // out of `standard` builds via the compile-time [enableDownloader] flag.
    if (!enableDownloader) return;
    final db = ref.read(downloaderDatabaseProvider);
    await service.exportDatabase(
      db,
      fileName: kHistoryBackupDownloaderFileName,
      schemaVersion: kDownloaderDatabaseSchemaVersion,
    );
  }

  /// True when this install holds no real history but the History folder has
  /// a usable snapshot that was never offered (covers the common case where
  /// storage permission — and therefore backup readability — is only granted
  /// after the first launch, when the pre-startup import already ran).
  Future<bool> checkPendingRestore() async {
    try {
      final service = await _service();
      if (!ref.mounted || service == null) return false;
      if (await HistoryBackupService.hasUserData(
        ref.read(appDatabaseProvider),
        ignoredTables: HistoryBackupService.appIgnoredTables,
      )) {
        return false;
      }
      if (!await service.hasRestorableBackup(
        fileName: kHistoryBackupAppFileName,
        schemaVersion: kAppDatabaseSchemaVersion,
      )) {
        return false;
      }
      return !await service.isRestoreDismissed();
    } catch (_) {
      return false;
    }
  }

  /// Closes the open databases and copies usable snapshots over the local
  /// files. Returns true when anything was restored. Providers still hold
  /// the closed instances, so the caller must restart the app afterwards
  /// (the WindowHost prompt closes it via [SystemNavigator.pop]).
  Future<bool> restoreNow() async {
    try {
      try {
        await ref.read(appDatabaseProvider).close();
      } catch (_) {}
      if (enableDownloader) {
        try {
          await ref.read(downloaderDatabaseProvider).close();
        } catch (_) {}
      }
      final service = await _service();
      if (!ref.mounted || service == null) return false;
      final app = await service.importAppDatabase();
      var downloader = false;
      if (enableDownloader) {
        downloader = await service.importDatabase(
          fileName: kHistoryBackupDownloaderFileName,
          schemaVersion: kDownloaderDatabaseSchemaVersion,
          openProbe: DownloaderDatabase.new,
        );
      }
      return app || downloader;
    } catch (_) {
      return false;
    }
  }

  Future<void> dismissRestore() async {
    try {
      final service = await _service();
      await service?.dismissRestorePrompt();
    } catch (_) {}
  }
}
