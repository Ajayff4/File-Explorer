import 'package:file_explorer/features/ftp/data/services/sftp_remote_service.dart';
import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:flutter_test/flutter_test.dart';

/// Live probe against a local asyncssh server (user/secret on 127.0.0.1:2223).
/// Skips when no server answers (CI machines have none).
void main() {
  test('lists real SFTP server folder via password', () async {
    final now = DateTime.now();
    final service = SftpRemoteService();
    try {
      await service.connect(
        FtpConnection(
          id: 'live-sftp',
          name: 'Live SFTP',
          protocol: FtpProtocol.sftp,
          host: '127.0.0.1',
          port: 2223,
          username: 'user',
          password: 'secret',
          remotePath: '/tmp/opencode/sftp-root',
          createdAt: now,
          updatedAt: now,
        ),
      );
    } catch (_) {
      markTestSkipped('No local SFTP server on 127.0.0.1:2223');
      return;
    }
    try {
      final entries =
          await service.listDirectory('/tmp/opencode/sftp-root');
      final names = entries.map((entry) => entry.name).toSet();
      expect(names, containsAll({'readme.txt', 'docs'}));
      final fileBytes =
          await service.downloadBytes('/tmp/opencode/sftp-root/readme.txt');
      expect(String.fromCharCodes(fileBytes).trim(), 'sftp-hello');
    } finally {
      await service.disconnect();
    }
  });
}
