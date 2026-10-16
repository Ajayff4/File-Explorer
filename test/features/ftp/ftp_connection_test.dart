import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:flutter_test/flutter_test.dart';

FtpConnection _connection({
  String id = '1',
  String name = 'Home',
  FtpProtocol protocol = FtpProtocol.ftp,
  String host = '192.168.1.10',
  int port = 21,
}) {
  final now = DateTime(2026);
  return FtpConnection(
    id: id,
    name: name,
    protocol: protocol,
    host: host,
    port: port,
    username: 'user',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('default ports match protocol', () {
    expect(FtpProtocol.ftp.defaultPort, 21);
    expect(FtpProtocol.sftp.defaultPort, 22);
    expect(FtpProtocol.ftps.defaultPort, 990);
  });

  test('valid connection passes validation', () {
    expect(_connection().validate(), isNull);
  });

  test('validation rejects empty name, bad host, bad port', () {
    expect(_connection(name: '  ').validate(), 'Name is required');
    expect(_connection(host: '').validate(), 'Host is required');
    expect(
      _connection(host: 'a b').validate(),
      'Host must not contain spaces',
    );
    expect(
      _connection(host: 'ftp://x').validate(),
      'Host must not include ://',
    );
    expect(_connection(port: 0).validate(), 'Port must be 1-65535');
    expect(_connection(port: 70000).validate(), 'Port must be 1-65535');
  });

  test('parsePort falls back to protocol default', () {
    expect(
      FtpConnection.parsePort('', protocol: FtpProtocol.sftp),
      22,
    );
    expect(
      FtpConnection.parsePort('abc', protocol: FtpProtocol.ftp),
      21,
    );
    expect(
      FtpConnection.parsePort('2121', protocol: FtpProtocol.ftp),
      2121,
    );
  });

  test('address formats host and port', () {
    expect(_connection(host: 'example.com', port: 2121).address,
        'example.com:2121');
  });

  test('sftp key auth requires username and key file', () {
    final now = DateTime(2026);
    FtpConnection keyConnection({String username = 'user', String? path}) {
      return FtpConnection(
        id: 'k',
        name: 'Key server',
        protocol: FtpProtocol.sftp,
        host: 'example.com',
        port: 22,
        username: username,
        sftpAuthType: SftpAuthType.privateKey,
        privateKeyPath: path,
        createdAt: now,
        updatedAt: now,
      );
    }

    expect(
      keyConnection().validate(),
      'Private key file is required',
    );
    expect(
      keyConnection(username: '  ', path: '/keys/id.ppk').validate(),
      'Username is required for key auth',
    );
    expect(
      keyConnection(path: '/keys/id.ppk').validate(),
      isNull,
    );
    expect(
      keyConnection(path: '/keys/id.ppk').usesPrivateKey,
      isTrue,
    );
    expect(
      keyConnection(path: '/keys/id.ppk').privateKeyFileName,
      'id.ppk',
    );
    expect(_connection().usesPrivateKey, isFalse);
  });

  test('key format sniff detects ppk and pem', () {
    expect(
      KeyFormat.sniff('PuTTY-User-Key-File-3: ssh-ed25519'),
      KeyFormat.ppk,
    );
    expect(
      KeyFormat.sniff('-----BEGIN OPENSSH PRIVATE KEY-----'),
      KeyFormat.openssh,
    );
    expect(
      KeyFormat.sniff('-----BEGIN RSA PRIVATE KEY-----'),
      KeyFormat.pem,
    );
  });
}
