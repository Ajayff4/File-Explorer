import 'package:file_explorer/features/ftp/data/repositories/in_memory_ftp_connection_store.dart';
import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/presentation/controllers/ftp_controller.dart';
import 'package:flutter_test/flutter_test.dart';

FtpConnection _connection(String id, {DateTime? updatedAt}) {
  final now = updatedAt ?? DateTime(2026);
  return FtpConnection(
    id: id,
    name: 'Server $id',
    protocol: FtpProtocol.ftp,
    host: '192.168.1.$id',
    port: 21,
    username: 'user',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('loads saved connections', () async {
    final store = InMemoryFtpConnectionStore();
    await store.saveConnection(_connection('1'));

    final controller = FtpController(store);
    await controller.loadConnections();

    expect(controller.state.connections.single.id, '1');
  });

  test('save upserts and sorts newest first', () async {
    final store = InMemoryFtpConnectionStore();
    final controller = FtpController(store);

    await controller.saveConnection(
      _connection('1', updatedAt: DateTime(2026, 1, 1)),
    );
    await controller.saveConnection(
      _connection('2', updatedAt: DateTime(2026, 1, 2)),
    );

    expect(
      controller.state.connections.map((connection) => connection.id),
      ['2', '1'],
    );

    await controller.saveConnection(
      _connection('1', updatedAt: DateTime(2026, 1, 3)),
    );
    expect(
      controller.state.connections.map((connection) => connection.id),
      ['1', '2'],
    );
    expect((await store.loadConnections()).length, 2);
  });

  test('save rejects invalid connection', () async {
    final store = InMemoryFtpConnectionStore();
    final controller = FtpController(store);

    await expectLater(
      controller.saveConnection(_connection('1').copyWith(host: '')),
      throwsArgumentError,
    );
    expect(controller.state.connections, isEmpty);
  });

  test('delete removes connection', () async {
    final store = InMemoryFtpConnectionStore();
    final controller = FtpController(store);

    await controller.saveConnection(_connection('1'));
    await controller.deleteConnection('1');

    expect(controller.state.connections, isEmpty);
    expect(await store.loadConnections(), isEmpty);
  });
}
