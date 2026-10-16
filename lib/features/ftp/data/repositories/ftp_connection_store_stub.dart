import 'package:file_explorer/features/ftp/data/repositories/in_memory_ftp_connection_store.dart';
import 'package:file_explorer/features/ftp/domain/repositories/ftp_connection_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

FtpConnectionStore createFtpConnectionStore(Ref ref) {
  return InMemoryFtpConnectionStore();
}
