import 'package:file_explorer/features/downloader/data/downloader_database.dart';
import 'package:file_explorer/features/downloader/data/downloader_database_connection_stub.dart'
    if (dart.library.io)
        'package:file_explorer/features/downloader/data/downloader_database_connection_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final downloaderDatabaseProvider = Provider<DownloaderDatabase>((ref) {
  final database = DownloaderDatabase(openDownloaderDatabaseConnection());
  ref.onDispose(database.close);
  return database;
});
