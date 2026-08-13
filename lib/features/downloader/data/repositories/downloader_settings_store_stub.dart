import 'package:file_explorer/features/downloader/data/repositories/in_memory_downloader_settings_store.dart';
import 'package:file_explorer/features/downloader/domain/repositories/downloader_settings_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

DownloaderSettingsStore createDownloaderSettingsStore(Ref ref) {
  return InMemoryDownloaderSettingsStore();
}