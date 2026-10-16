import 'dart:typed_data';

import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/domain/entities/remote_entry.dart';

/// Live connection to a remote server described by [FtpConnection].
/// One instance per browser session; call [disconnect] when done.
abstract interface class RemoteFileService {
  Future<void> connect(FtpConnection connection);

  Future<List<RemoteEntry>> listDirectory(String path);

  Future<Uint8List> downloadBytes(String remotePath);

  Future<void> disconnect();
}

/// Thrown when the saved connection cannot be used as-is
/// (missing key file, unsupported PPK format, ...).
class RemoteConnectionException implements Exception {
  const RemoteConnectionException(this.message);

  final String message;

  @override
  String toString() => 'RemoteConnectionException: $message';
}
