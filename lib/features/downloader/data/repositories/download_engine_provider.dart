import 'package:file_explorer/features/downloader/data/repositories/download_engine_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/downloader/data/repositories/download_engine_io.dart';
import 'package:file_explorer/features/downloader/domain/repositories/download_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final downloadEngineProvider = Provider<DownloadEngine>((ref) {
  return createDownloadEngine();
});