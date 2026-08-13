import 'package:file_explorer/features/downloader/domain/repositories/downloader_settings_store.dart';
import 'package:file_explorer/shared/database/app_database.dart';

class DriftDownloaderSettingsStore implements DownloaderSettingsStore {
  const DriftDownloaderSettingsStore(this._database);

  static const _maxConcurrentKey = 'downloader.max_concurrent_downloads';
  static const _outputDirectoryKey = 'downloader.output_directory';

  final AppDatabase _database;

  @override
  Future<DownloaderSettings> load() async {
    final rows = await _database.select(_database.settingRows).get();
    final values = {
      for (final row in rows) row.key: row.value,
    };

    final maxConcurrent =
        int.tryParse(values[_maxConcurrentKey] ?? '') ?? 1;
    return DownloaderSettings(
      maxConcurrentDownloads: maxConcurrent.clamp(1, 16),
      outputDirectory: values[_outputDirectoryKey] ?? '',
    );
  }

  @override
  Future<void> save(DownloaderSettings settings) async {
    final now = DateTime.now();
    await _database.into(_database.settingRows).insertOnConflictUpdate(
      SettingRowsCompanion.insert(
        key: _maxConcurrentKey,
        value: '${settings.maxConcurrentDownloads}',
        updatedAt: now,
      ),
    );
    await _database.into(_database.settingRows).insertOnConflictUpdate(
      SettingRowsCompanion.insert(
        key: _outputDirectoryKey,
        value: settings.outputDirectory,
        updatedAt: now,
      ),
    );
  }
}