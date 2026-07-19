import 'package:file_explorer/shared/database/app_database.dart';
import 'package:file_explorer/shared/database/app_database_connection_stub.dart'
    if (dart.library.io) 'package:file_explorer/shared/database/app_database_connection_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(openAppDatabaseConnection());
  ref.onDispose(database.close);
  return database;
});
