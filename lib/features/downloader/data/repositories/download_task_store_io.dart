import 'package:file_explorer/features/downloader/data/repositories/drift_download_task_store.dart';
import 'package:file_explorer/features/downloader/domain/repositories/download_task_store.dart';
import 'package:file_explorer/shared/database/app_database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

DownloadTaskStore createDownloadTaskStore(Ref ref) {
  return DriftDownloadTaskStore(ref.watch(appDatabaseProvider));
}
