import 'package:file_explorer/features/ftp/data/services/ftp_remote_service.dart';
import 'package:file_explorer/features/ftp/data/services/sftp_remote_service.dart';
import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/domain/repositories/remote_file_service.dart';

/// One live [RemoteFileService] per protocol.
RemoteFileService createRemoteFileService(FtpProtocol protocol) {
  return switch (protocol) {
    FtpProtocol.sftp => SftpRemoteService(),
    FtpProtocol.ftp || FtpProtocol.ftps => FtpRemoteService(),
  };
}
