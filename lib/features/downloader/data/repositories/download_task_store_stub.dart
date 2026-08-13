import 'package:file_explorer/features/downloader/data/repositories/in_memory_download_task_store.dart';
import 'package:file_explorer/features/downloader/domain/repositories/download_task_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

DownloadTaskStore createDownloadTaskStore(Ref ref) {
  return InMemoryDownloadTaskStore();
}