import 'dart:typed_data';

import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/domain/entities/remote_entry.dart';
import 'package:file_explorer/features/ftp/domain/repositories/remote_file_service.dart';
import 'package:ftpconnect/ftpconnect.dart';

/// FTP and FTPS (explicit) browsing via `ftpconnect`.
class FtpRemoteService implements RemoteFileService {
  FTPConnect? _client;

  @override
  Future<void> connect(FtpConnection connection) async {
    await disconnect();
    // NOTE: do not pass transferType here. FTPSocket stores the value
    // without sending TYPE, and setTransferType() no-ops when the value
    // matches — so construct as auto, then switch to binary below.
    final client = FTPConnect(
      connection.host,
      user: connection.username.isEmpty ? 'anonymous' : connection.username,
      pass: connection.password ?? '',
      port: connection.port,
      securityType: connection.protocol == FtpProtocol.ftps
          ? SecurityType.ftps
          : SecurityType.ftp,
      timeout: 15,
      transferMode:
          connection.passiveMode ? TransferMode.passive : TransferMode.active,
    );
    await client.connect();
    // Binary (TYPE I) for exact bytes. `auto` means ASCII (TYPE A), whose
    // CRLF translation corrupts images/archives.
    await client.setTransferType(TransferType.binary);
    _client = client;
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
