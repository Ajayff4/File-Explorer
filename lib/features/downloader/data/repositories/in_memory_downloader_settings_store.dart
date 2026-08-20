import 'package:file_explorer/features/downloader/domain/repositories/downloader_settings_store.dart';

class InMemoryDownloaderSettingsStore implements DownloaderSettingsStore {
  DownloaderSettings _settings = const DownloaderSettings();

  @override
  Future<DownloaderSettings> load() async => _settings;

  @override
  Future<void> save(DownloaderSettings settings) async {
    _settings = settings;
  }
}
