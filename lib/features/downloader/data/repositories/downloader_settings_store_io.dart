import 'package:file_explorer/features/downloader/data/repositories/drift_downloader_settings_store.dart';
import 'package:file_explorer/features/downloader/domain/repositories/downloader_settings_store.dart';
import 'package:file_explorer/shared/database/app_database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

DownloaderSettingsStore createDownloaderSettingsStore(Ref ref) {
  return DriftDownloaderSettingsStore(ref.watch(appDatabaseProvider));
}