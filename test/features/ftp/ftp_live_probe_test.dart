import 'package:file_explorer/features/ftp/data/services/ftp_remote_service.dart';
import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:flutter_test/flutter_test.dart';

/// Live probe against a local pyftpdlib server:
/// `python3 -m pyftpdlib -p 2121 -u user -P secret -w -d <dir>`
/// Skips when no server answers (CI machines have none).
void main() {
  test('lists real FTP server root', () async {
    final now = DateTime.now();
    final service = FtpRemoteService();
    try {
      await service.connect(
        FtpConnection(
          id: 'live',
          name: 'Live',
          protocol: FtpProtocol.ftp,
          host: '127.0.0.1',
          port: 2121,
          username: 'user',
          password: 'secret',
          createdAt: now,
          updatedAt: now,
        ),
      );
    } catch (_) {
      markTestSkipped('No local FTP server on 127.0.0.1:2121');
      return;
    }
    try {
      final entries = await service.listDirectory('/');
      final names = entries.map((entry) => entry.name).toSet();
      expect(names, containsAll({'readme.txt', 'docs'}));
      final docs =
          entries.firstWhere((entry) => entry.name == 'docs');
      expect(docs.isDirectory, isTrue);
      final sub = await service.listDirectory('/docs');
      expect(sub.map((entry) => entry.name), contains('note.txt'));
    } finally {
      await service.disconnect();
    }
  });
}
