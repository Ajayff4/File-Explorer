import 'dart:io';
import 'dart:typed_data';

import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/domain/entities/remote_entry.dart';
import 'package:file_explorer/features/ftp/domain/repositories/remote_file_service.dart';
import 'package:ftpconnect/ftpconnect.dart';

/// SFTP browsing via `ftpconnect`'s `SFTPConnect` (dartssh2 underneath).
class SftpRemoteService implements RemoteFileService {
  SFTPConnect? _client;

  @override
  Future<void> connect(FtpConnection connection) async {
    await disconnect();
    String? keyContent;
    if (connection.usesPrivateKey) {
      keyContent = await _readKeyFile(connection);
    }
    final client = SFTPConnect(
      connection.host,
      port: connection.port,
      user: connection.username,
      pass: keyContent == null ? (connection.password ?? '') : '',
      privateKey: keyContent,
      passphrase: keyContent == null ? null : connection.passphrase,
      timeout: 15,
    );
    await client.connect();
    _client = client;
  }

  /// Reads the key file and rejects PPK (needs PuTTYgen export to OpenSSH).
  Future<String> _readKeyFile(FtpConnection connection) async {
    final path = connection.privateKeyPath;
    if (path == null || path.isEmpty) {
      throw const RemoteConnectionException('Private key file is required');
    }
    late final String content;
    try {
      content = await File(path).readAsString();
    } catch (_) {
      throw RemoteConnectionException('Cannot read key file: $path');
    }
    final format = connection.keyFormat == KeyFormat.auto
        ? KeyFormat.sniff(content)
        : connection.keyFormat;
    if (format == KeyFormat.ppk) {
      throw const RemoteConnectionException(
        'PPK keys need export to OpenSSH format (PuTTYgen > Conversions > Export OpenSSH key)',
      );
    }
    return content;
  }

  @override
  Future<List<RemoteEntry>> listDirectory(String path) async {
    final client = _client;
    if (client == null) {
      throw const RemoteConnectionException('Not connected');
    }
    final entries = await client.listDirectoryContent(path);
    return RemoteEntry.sorted([
      for (final entry in entries)
        if (entry.name != '.' && entry.name != '..')
          RemoteEntry(
            name: entry.name,
            path: _join(path, entry.name),
            isDirectory: entry.type == FTPEntryType.dir,
            sizeBytes: entry.size,
            modifiedAt: entry.modifyTime,
          ),
    ]);
  }

  @override
  Future<Uint8List> downloadBytes(String remotePath) async {
    final client = _client;
    if (client == null) {
      throw const RemoteConnectionException('Not connected');
    }
    return client.downloadToBytes(remotePath);
  }

  @override
  Future<void> disconnect() async {
    final client = _client;
    _client = null;
    if (client == null) return;
    try {
      await client.disconnect();
    } catch (_) {
      // Best effort; session already gone or never opened.
    }
  }

  String _join(String dir, String name) {
    if (dir.endsWith('/')) return '$dir$name';
    return '$dir/$name';
  }
}
