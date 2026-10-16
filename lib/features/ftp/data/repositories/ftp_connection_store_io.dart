import 'package:file_explorer/features/ftp/data/repositories/drift_ftp_connection_store.dart';
import 'package:file_explorer/features/ftp/domain/repositories/ftp_connection_store.dart';
import 'package:file_explorer/shared/database/app_database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

FtpConnectionStore createFtpConnectionStore(Ref ref) {
  return DriftFtpConnectionStore(ref.watch(appDatabaseProvider));
}
