import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';

abstract interface class FtpConnectionStore {
  Future<List<FtpConnection>> loadConnections();
  Future<void> saveConnection(FtpConnection connection);
  Future<void> deleteConnection(String id);
}
