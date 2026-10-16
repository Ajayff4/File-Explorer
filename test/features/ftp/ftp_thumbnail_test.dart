import 'dart:convert';
import 'dart:typed_data';

import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/domain/entities/remote_entry.dart';
import 'package:file_explorer/features/ftp/domain/repositories/remote_file_service.dart';
import 'package:file_explorer/features/ftp/presentation/controllers/ftp_browser_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class CountingFake implements RemoteFileService {
  int downloadCalls = 0;

  static final png1x1 = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  @override
  Future<void> connect(FtpConnection connection) async {}

  @override
  Future<List<RemoteEntry>> listDirectory(String path) async => const [];

  @override
  Future<Uint8List> downloadBytes(String remotePath) async {
    downloadCalls++;
    if (remotePath.endsWith('.png')) return png1x1;
    throw const RemoteConnectionException('No such file');
  }

  @override
  Future<void> disconnect() async {}
}

FtpBrowserController _controller(CountingFake service) {
  final now = DateTime(2026);
  return FtpBrowserController(
    service,
    FtpConnection(
      id: '1',
      name: 'S',
      protocol: FtpProtocol.ftp,
      host: 'h',
      port: 21,
      username: 'u',
      createdAt: now,
      updatedAt: now,
    ),
  );
}

RemoteEntry _entry(String name, {bool dir = false, int? size}) {
  return RemoteEntry(
    name: name,
    path: '/$name',
    isDirectory: dir,
    sizeBytes: size,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('isImageName detects images only', () {
    expect(FtpBrowserController.isImageName('a.png'), isTrue);
    expect(FtpBrowserController.isImageName('a.JPG'), isTrue);
    expect(FtpBrowserController.isImageName('a.txt'), isFalse);
    expect(FtpBrowserController.isImageName('noext'), isFalse);
  });

  test('thumbnail for png, cached on second call', () async {
    final service = CountingFake();
    final controller = _controller(service);

    final first = await controller.thumbnailFor(_entry('a.png'));
    expect(first, isNotNull);
    expect(first!.isNotEmpty, isTrue);

    final second = await controller.thumbnailFor(_entry('a.png'));
    expect(second, isNotNull);
    expect(service.downloadCalls, 1);
  });

  test('null for folders, text, oversize, failures', () async {
    final service = CountingFake();
    final controller = _controller(service);

    expect(await controller.thumbnailFor(_entry('d', dir: true)), isNull);
    expect(await controller.thumbnailFor(_entry('a.txt')), isNull);
    expect(
      await controller.thumbnailFor(
        _entry('big.png', size: 21 * 1024 * 1024),
      ),
      isNull,
    );
    expect(await controller.thumbnailFor(_entry('a.gif')), isNull);
    expect(service.downloadCalls, 1);
  });
}
