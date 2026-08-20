import 'package:file_explorer/features/downloader/data/repositories/downloader_settings_store_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/downloader/data/repositories/downloader_settings_store_io.dart';
import 'package:file_explorer/features/downloader/domain/repositories/downloader_settings_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final downloaderSettingsStoreProvider =
    Provider<DownloaderSettingsStore>((ref) {
  return createDownloaderSettingsStore(ref);
});
