import 'package:file_explorer/features/downloader/data/repositories/download_task_store_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/downloader/data/repositories/download_task_store_io.dart';
import 'package:file_explorer/features/downloader/domain/repositories/download_task_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final downloadTaskStoreProvider = Provider<DownloadTaskStore>((ref) {
  return createDownloadTaskStore(ref);
});
