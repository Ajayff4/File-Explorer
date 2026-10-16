import 'package:drift/drift.dart';
import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/domain/repositories/ftp_connection_store.dart';
import 'package:file_explorer/shared/database/app_database.dart';

class DriftFtpConnectionStore implements FtpConnectionStore {
  const DriftFtpConnectionStore(this._database);

  final AppDatabase _database;

  @override
  Future<List<FtpConnection>> loadConnections() async {
    final rows = await (_database.select(_database.ftpConnectionRows)
          ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]))
        .get();
    return rows.map(_toConnection).toList();
  }

  @override
  Future<void> saveConnection(FtpConnection connection) {
    return _database
        .into(_database.ftpConnectionRows)
        .insertOnConflictUpdate(_toCompanion(connection));
  }

  @override
  Future<void> deleteConnection(String id) {
    return (_database.delete(_database.ftpConnectionRows)
          ..where((table) => table.id.equals(id)))
        .go();
  }

  FtpConnection _toConnection(FtpConnectionRow row) {
    return FtpConnection(
      id: row.id,
      name: row.name,
      protocol: row.protocol,
      host: row.host,
      port: row.port,
      username: row.username,
      password: row.password,
      remotePath: row.remotePath,
      passiveMode: row.passiveMode,
      acceptInvalidCert: row.acceptInvalidCert,
      sftpAuthType: row.sftpAuthType,
      privateKeyPath: row.privateKeyPath,
      keyFormat: row.keyFormat,
      passphrase: row.passphrase,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  FtpConnectionRowsCompanion _toCompanion(FtpConnection connection) {
    return FtpConnectionRowsCompanion.insert(
      id: connection.id,
      name: connection.name,
      protocol: connection.protocol,
      host: connection.host,
      port: connection.port,
      username: Value(connection.username),
      password: Value(connection.password),
      remotePath: Value(connection.remotePath),
      passiveMode: Value(connection.passiveMode),
      acceptInvalidCert: Value(connection.acceptInvalidCert),
      sftpAuthType: Value(connection.sftpAuthType),
      privateKeyPath: Value(connection.privateKeyPath),
      keyFormat: Value(connection.keyFormat),
      passphrase: Value(connection.passphrase),
      createdAt: connection.createdAt,
      updatedAt: connection.updatedAt,
    );
  }
}
