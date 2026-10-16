import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/domain/repositories/ftp_connection_store.dart';

class InMemoryFtpConnectionStore implements FtpConnectionStore {
  final Map<String, FtpConnection> _connections = {};

  @override
  Future<List<FtpConnection>> loadConnections() async {
    final connections = _connections.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return connections;
  }

  @override
  Future<void> saveConnection(FtpConnection connection) async {
    _connections[connection.id] = connection;
  }

  @override
  Future<void> deleteConnection(String id) async {
    _connections.remove(id);
  }
}
