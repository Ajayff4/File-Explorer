import 'package:file_explorer/features/downloader/data/downloader_database.dart';
import 'package:file_explorer/features/downloader/data/downloader_database_connection_stub.dart'
    if (dart.library.io)
        'package:file_explorer/features/downloader/data/downloader_database_connection_io.dart';
import 'package:file_explorer/features/downloader/data/downloader_history_backup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final downloaderDatabaseProvider = Provider<DownloaderDatabase>((ref) {
  // Register the history-backup backend on first use. This initializer only
  // ever runs when the downloader feature is compiled in, which is also what
  // makes it safe: shared backup code never references downloader types.
  registerDownloaderBackup(ref);
  final database = DownloaderDatabase(openDownloaderDatabaseConnection());
  ref.onDispose(database.close);
  return database;
});
