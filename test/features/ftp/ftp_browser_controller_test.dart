import 'dart:typed_data';

import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/domain/entities/remote_entry.dart';
import 'package:file_explorer/features/ftp/domain/repositories/remote_file_service.dart';
import 'package:file_explorer/features/ftp/presentation/controllers/ftp_browser_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRemoteService implements RemoteFileService {
  FakeRemoteService({this.listings = const {}, this.failConnect = false});

  final Map<String, List<RemoteEntry>> listings;
  final bool failConnect;
  bool connected = false;
  bool disconnected = false;

  @override
  Future<void> connect(FtpConnection connection) async {
    if (failConnect) throw const RemoteConnectionException('refused');
    connected = true;
  }

  @override
  Future<List<RemoteEntry>> listDirectory(String path) async {
    final listing = listings[path];
    if (listing == null) {
      throw const RemoteConnectionException('No such folder');
    }
    return listing;
  }

  @override
  Future<Uint8List> downloadBytes(String remotePath) async {
    if (remotePath == '/a.txt') return Uint8List.fromList([1, 2, 3]);
    throw const RemoteConnectionException('No such file');
  }

  @override
  Future<void> disconnect() async {
    disconnected = true;
  }
}

FtpConnection _connection() {
  final now = DateTime(2026);
  return FtpConnection(
    id: '1',
    name: 'Local',
    protocol: FtpProtocol.ftp,
    host: '127.0.0.1',
    port: 2121,
    username: 'user',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('connect loads initial folder', () async {
    final service = FakeRemoteService(listings: {
      '/': const [
        RemoteEntry(name: 'docs', path: '/docs', isDirectory: true),
        RemoteEntry(name: 'a.txt', path: '/a.txt', isDirectory: false),
      ],
    });
    final controller = FtpBrowserController(service, _connection());
    await controller.connect();

    expect(service.connected, isTrue);
    expect(controller.state.isConnecting, isFalse);
    expect(controller.state.currentPath, '/');
    expect(
      controller.state.entries.map((entry) => entry.name),
      ['docs', 'a.txt'],
    );
  });

  test('open directory and go up', () async {
    final service = FakeRemoteService(listings: {
      '/': const [
        RemoteEntry(name: 'docs', path: '/docs', isDirectory: true),
      ],
      '/docs': const [
        RemoteEntry(name: 'b.txt', path: '/docs/b.txt', isDirectory: false),
      ],
    });
    final controller = FtpBrowserController(service, _connection());
    await controller.connect();
    await controller.openDirectory('/docs');

    expect(controller.state.currentPath, '/docs');
    expect(controller.state.entries.single.name, 'b.txt');

    await controller.goUp();
    expect(controller.state.currentPath, '/');
  });

  test('failed connect surfaces error', () async {
    final service = FakeRemoteService(failConnect: true);
    final controller = FtpBrowserController(service, _connection());
    await controller.connect();

    expect(controller.state.isConnecting, isFalse);
    expect(controller.state.error, 'refused');
  });

  test('missing folder surfaces error', () async {
    final service = FakeRemoteService(listings: const {});
    final controller = FtpBrowserController(service, _connection());
    await controller.connect();
    await controller.openDirectory('/nope');

    expect(controller.state.error, 'No such folder');
  });

  test('toggleView flips grid mode', () async {
    final service = FakeRemoteService(listings: const {});
    final controller = FtpBrowserController(service, _connection());

    expect(controller.state.isGrid, isFalse);
    controller.toggleView();
    expect(controller.state.isGrid, isTrue);
    controller.toggleView();
    expect(controller.state.isGrid, isFalse);
  });

  test('dispose disconnects', () async {
    final service = FakeRemoteService(listings: const {});
    final controller = FtpBrowserController(service, _connection());
    await controller.connect();
    controller.dispose();

    expect(service.disconnected, isTrue);
  });

  test('download bytes delegates to service', () async {
    final service = FakeRemoteService(listings: const {});
    final controller = FtpBrowserController(service, _connection());
    await controller.connect();

    expect(await controller.downloadBytes('/a.txt'), [1, 2, 3]);
    expect(
      controller.downloadErrorMessage(
        const RemoteConnectionException('No such file'),
      ),
      'No such file',
    );
  });
}
