import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/domain/entities/remote_entry.dart';
import 'package:file_explorer/features/ftp/domain/repositories/remote_file_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:xml/xml.dart';

/// WebDAV browsing via PROPFIND over HTTP/HTTPS.
class WebDavRemoteService implements RemoteFileService {
  FtpConnection? _connection;
  http.Client? _client;

  @override
  Future<void> connect(FtpConnection connection) async {
    await disconnect();
    _connection = connection;
    final secure = connection.protocol == FtpProtocol.webdavs;
    final httpClient = HttpClient();
    if (secure && connection.acceptInvalidCert) {
      httpClient.badCertificateCallback = (cert, host, port) => true;
    }
    _client = IOClient(httpClient);
    await listDirectory(
      connection.remotePath.isEmpty ? '/' : connection.remotePath,
    );
  }

  @override
  Future<List<RemoteEntry>> listDirectory(String path) async {
    final client = _client;
    final connection = _connection;
    if (client == null || connection == null) {
      throw const RemoteConnectionException('Not connected');
    }
    final normalized = _normalizePath(path);
    final uri = _uriFor(normalized, connection);
    final request = http.Request('PROPFIND', uri);
    request.headers.addAll(_headers(connection));
    request.headers['Depth'] = '1';
    request.headers['Content-Type'] = 'application/xml; charset=utf-8';
    request.body =
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<d:propfind xmlns:d="DAV:"><d:prop>'
        '<d:displayname/><d:resourcetype/>'
        '<d:getcontentlength/><d:getlastmodified/>'
        '</d:prop></d:propfind>';

    final streamed = await client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 207 && response.statusCode != 200) {
      throw RemoteConnectionException(
        'WebDAV error ${response.statusCode}: ${response.body}',
      );
    }
    return _parseMultistatus(response.body, normalized);
  }

  @override
  Future<Uint8List> downloadBytes(String remotePath) async {
    final client = _client;
    final connection = _connection;
    if (client == null || connection == null) {
      throw const RemoteConnectionException('Not connected');
    }
    final uri = _uriFor(_normalizePath(remotePath), connection);
    final response = await client.get(uri, headers: _authHeaders(connection));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteConnectionException(
        'WebDAV download failed (${response.statusCode})',
      );
    }
    return response.bodyBytes;
  }

  @override
  Future<void> disconnect() async {
    final client = _client;
    _client = null;
    _connection = null;
    if (client != null) {
      try {
        client.close();
      } catch (_) {
        // Best effort.
      }
    }
  }

  Map<String, String> _headers(FtpConnection connection) {
    return _authHeaders(connection);
  }

  Map<String, String> _authHeaders(FtpConnection connection) {
    final headers = <String, String>{};
    if (connection.username.isNotEmpty) {
      final credentials = base64Encode(
        utf8.encode('${connection.username}:${connection.password ?? ''}'),
      );
      headers['Authorization'] = 'Basic $credentials';
    }
    return headers;
  }

  Uri _uriFor(String path, FtpConnection connection) {
    final secure = connection.protocol == FtpProtocol.webdavs;
    return Uri(
      scheme: secure ? 'https' : 'http',
      host: connection.host,
      port: connection.port,
      path: path,
    );
  }

  String _normalizePath(String path) {
    if (path.trim().isEmpty) return '/';
    var normalized = path.trim();
    if (!normalized.startsWith('/')) normalized = '/$normalized';
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  List<RemoteEntry> _parseMultistatus(String body, String requestPath) {
    final document = XmlDocument.parse(body);
    final entries = <RemoteEntry>[];
    for (final response in document.descendants.whereType<XmlElement>().where(
      (element) => element.name.local == 'response',
    )) {
      final hrefElement = response.children
          .whereType<XmlElement>()
          .firstWhere(
            (element) => element.name.local == 'href',
            orElse: () => XmlElement(XmlName('href')),
          );
      final href = hrefElement.innerText.trim();
      if (href.isEmpty) continue;
      final uri = Uri.parse(href);
      var path = uri.path;
      if (path.isEmpty) path = '/';
      if (path.length > 1 && path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
      }
      if (path == requestPath) continue;

      final propstat = response.descendants
          .whereType<XmlElement>()
          .firstWhere(
            (element) => element.name.local == 'propstat',
            orElse: () => XmlElement(XmlName('propstat')),
          );
      final prop = propstat.children
          .whereType<XmlElement>()
          .firstWhere(
            (element) => element.name.local == 'prop',
            orElse: () => XmlElement(XmlName('prop')),
          );

      final resourceType = prop.children
          .whereType<XmlElement>()
          .firstWhere(
            (element) => element.name.local == 'resourcetype',
            orElse: () => XmlElement(XmlName('resourcetype')),
          );
      final isDirectory = resourceType.descendants.whereType<XmlElement>().any(
        (element) => element.name.local == 'collection',
      );

      final displayNameElement = prop.children
          .whereType<XmlElement>()
          .firstWhere(
            (element) => element.name.local == 'displayname',
            orElse: () => XmlElement(XmlName('displayname')),
          );
      final displayName = displayNameElement.innerText.trim();

      final sizeElement = prop.children
          .whereType<XmlElement>()
          .firstWhere(
            (element) => element.name.local == 'getcontentlength',
            orElse: () => XmlElement(XmlName('getcontentlength')),
          );
      final sizeBytes = int.tryParse(sizeElement.innerText.trim());

      final modifiedElement = prop.children
          .whereType<XmlElement>()
          .firstWhere(
            (element) => element.name.local == 'getlastmodified',
            orElse: () => XmlElement(XmlName('getlastmodified')),
          );
      DateTime? modifiedAt;
      final modifiedText = modifiedElement.innerText.trim();
      if (modifiedText.isNotEmpty) {
        try {
          modifiedAt = HttpDate.parse(modifiedText);
        } catch (_) {
          modifiedAt = DateTime.tryParse(modifiedText);
        }
      }

      final segments = path.split('/');
      final fallbackName = segments.isEmpty ? path : segments.last;
      final name = displayName.isNotEmpty
          ? displayName
          : Uri.decodeComponent(fallbackName);

      entries.add(
        RemoteEntry(
          name: name.isEmpty ? path : name,
          path: path,
          isDirectory: isDirectory,
          sizeBytes: sizeBytes,
          modifiedAt: modifiedAt,
        ),
      );
    }
    return RemoteEntry.sorted(entries);
  }
}
