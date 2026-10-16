import 'package:file_explorer/features/ftp/data/repositories/ftp_connection_store_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/ftp/data/repositories/ftp_connection_store_io.dart';
import 'package:file_explorer/features/ftp/domain/repositories/ftp_connection_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ftpConnectionStoreProvider = Provider<FtpConnectionStore>((ref) {
  return createFtpConnectionStore(ref);
});
