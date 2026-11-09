import 'dart:io';
import 'dart:typed_data';

import 'package:file_explorer/features/ftp/data/services/webdav_remote_service.dart';
import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late int port;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    port = server.port;
    server.listen((request) async {
      if (request.method == 'PROPFIND' && request.uri.path == '/dav') {
        request.response.statusCode = 207;
        request.response.headers.contentType = ContentType('application', 'xml');
        request.response.write('''
<?xml version="1.0" encoding="UTF-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/dav/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>dav</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/dav/folder/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>folder</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
        <d:getlastmodified>Wed, 01 Jan 2020 00:00:00 GMT</d:getlastmodified>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/dav/file.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>file.txt</d:displayname>
        <d:resourcetype/>
        <d:getcontentlength>5</d:getcontentlength>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''');
        await request.response.close();
        return;
      }
      if (request.method == 'GET' && request.uri.path == '/dav/file.txt') {
        request.response.add([1, 2, 3, 4, 5]);
        await request.response.close();
        return;
      }
      request.response.statusCode = 404;
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('lists WebDAV entries and downloads a file', () async {
    final service = WebDavRemoteService();
    final connection = FtpConnection(
      id: '1',
      name: 'dav',
      protocol: FtpProtocol.webdav,
      host: '127.0.0.1',
      port: port,
      username: 'user',
      password: 'pass',
      remotePath: '/dav',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await service.connect(connection);
    final entries = await service.listDirectory('/dav');

    expect(entries, hasLength(2));
    expect(entries.first.name, 'folder');
    expect(entries.first.isDirectory, isTrue);
    expect(entries.last.name, 'file.txt');
    expect(entries.last.sizeBytes, 5);

    final bytes = await service.downloadBytes('/dav/file.txt');
    expect(bytes, Uint8List.fromList([1, 2, 3, 4, 5]));

    await service.disconnect();
  });
}
