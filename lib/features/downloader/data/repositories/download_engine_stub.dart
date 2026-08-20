import 'package:file_explorer/features/downloader/data/repositories/fake_download_engine.dart';
import 'package:file_explorer/features/downloader/domain/repositories/download_engine.dart';

DownloadEngine createDownloadEngine() {
  return FakeDownloadEngine();
}
