import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Extension used for encrypted files.
const ff4Extension = '.ff4';

/// Whether [path] points to an encrypted `.ff4` container.
bool isEncryptedFile(String path) => path.toLowerCase().endsWith(ff4Extension);

/// Thrown when a `.ff4` container cannot be decrypted with the given password.
class WrongPasswordException implements Exception {
  const WrongPasswordException();

  @override
  String toString() => 'WrongPasswordException: incorrect password';
}

/// A decrypted payload: the recovered file name (with its original extension,
/// so the type is restored) and the clear-text bytes.
class DecryptedFile {
  const DecryptedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// A derived key + salt reused across one bulk operation so the password is
/// stretched once instead of once per file.
class EncryptionSession {
  EncryptionSession._(this.salt, this._key);

  final List<int> salt;
  final SecretKey _key;
}

class _ContainerHeader {
  const _ContainerHeader({
    required this.encryptName,
    required this.salt,
    required this.nonce,
    required this.name,
    required this.cipherText,
    required this.tag,
  });

  final bool encryptName;
  final List<int> salt;
  final List<int> nonce;
  final String name;
  final List<int> cipherText;
  final List<int> tag;
}

/// AES-256-GCM encryption of file bytes with a PBKDF2-HMAC-SHA256 password key.
///
/// Container layout (all integers big-endian):
/// ```
/// magic "FF4" (3) | version u8 | flags u8 (bit0 = encryptName) | saltLen u8
/// | salt | iterations u32 | nonceLen u8 | nonce | nameLen u32 | name
/// | cipherLen u32 | cipherText | tag (16)
/// ```
///
/// When `encryptName` is true the header `name` field is empty and the original
/// name is stored (length-prefixed) inside the encrypted payload instead.
class EncryptionService {
  EncryptionService({Pbkdf2? pbkdf2, AesGcm? aes})
      : _pbkdf2 = pbkdf2 ?? Pbkdf2.hmacSha256(iterations: iterations, bits: 256),
        _aes = aes ?? AesGcm.with256bits();

  static const String magic = 'FF4';
  static const int version = 1;
  static const int iterations = 100000;
  static const int saltLength = 16;
  static const int tagLength = 16;

  final Pbkdf2 _pbkdf2;
  final AesGcm _aes;

  Future<EncryptionSession> openSession(String password) async {
    final salt = _secureRandom(saltLength);
    final key = await _pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    return EncryptionSession._(salt, key);
  }

  Future<Uint8List> encrypt(
    Uint8List content,
    EncryptionSession session,
    String name, {
    required bool encryptName,
  }) async {
    final nameBytes = utf8.encode(name);
    final payload = encryptName
        ? _concat([_u32(nameBytes.length), nameBytes, content])
        : content;
    final box = await _aes.encrypt(payload, secretKey: session._key);
    return _buildContainer(
      salt: session.salt,
      box: box,
      name: encryptName ? '' : name,
      encryptName: encryptName,
    );
  }

  Future<DecryptedFile> decrypt(Uint8List container, String password) async {
    final header = _parse(container);
    final key = await _pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: header.salt,
    );
    final box = SecretBox(
      header.cipherText,
      nonce: header.nonce,
      mac: Mac(header.tag),
    );
    final List<int> decrypted;
    try {
      decrypted = await _aes.decrypt(box, secretKey: key);
    } on SecretBoxAuthenticationError {
      throw const WrongPasswordException();
    }
    final clear = Uint8List.fromList(decrypted);

    final String name;
    final Uint8List content;
    if (header.encryptName) {
      final nameLen = _readU32(clear, 0);
      name = utf8.decode(clear.sublist(4, 4 + nameLen));
      content = clear.sublist(4 + nameLen);
    } else {
      name = header.name;
      content = clear;
    }
    return DecryptedFile(name: name, bytes: content);
  }

  Uint8List _buildContainer({
    required List<int> salt,
    required SecretBox box,
    required String name,
    required bool encryptName,
  }) {
    final builder = BytesBuilder();
    builder.add(utf8.encode(magic));
    builder.addByte(version);
    builder.addByte(encryptName ? 1 : 0);
    builder.addByte(salt.length);
    builder.add(salt);
    builder.add(_u32(iterations));
    builder.addByte(box.nonce.length);
    builder.add(box.nonce);
    final nameBytes = encryptName ? const <int>[] : utf8.encode(name);
    builder.add(_u32(nameBytes.length));
    builder.add(nameBytes);
    builder.add(_u32(box.cipherText.length));
    builder.add(box.cipherText);
    builder.add(box.mac.bytes);
    return builder.toBytes();
  }

  _ContainerHeader _parse(Uint8List data) {
    if (data.length < 3 + 1 + 1 + 1) {
      throw const FormatException('Not a valid FF4 file');
    }
    if (utf8.decode(data.sublist(0, 3)) != magic) {
      throw const FormatException('Not a valid FF4 file');
    }
    var pos = 3;
    pos += 1; // version
    final flags = data[pos++];
    final encryptName = (flags & 1) == 1;
    final saltLen = data[pos++];
    final salt = data.sublist(pos, pos + saltLen);
    pos += saltLen;
    pos += 4; // iterations (not re-read; service uses its own constant)
    final nonceLen = data[pos++];
    final nonce = data.sublist(pos, pos + nonceLen);
    pos += nonceLen;
    final nameLen = _readU32(data, pos);
    pos += 4;
    final name = nameLen == 0
        ? ''
        : utf8.decode(data.sublist(pos, pos + nameLen));
    pos += nameLen;
    final cipherLen = _readU32(data, pos);
    pos += 4;
    final cipherText = data.sublist(pos, pos + cipherLen);
    pos += cipherLen;
    final tag = data.sublist(pos, pos + tagLength);
    return _ContainerHeader(
      encryptName: encryptName,
      salt: salt,
      nonce: nonce,
      name: name,
      cipherText: cipherText,
      tag: tag,
    );
  }
}

Uint8List _secureRandom(int length) {
  final random = Random.secure();
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = random.nextInt(256);
  }
  return bytes;
}

List<int> _u32(int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.big);
  return data.buffer.asUint8List();
}

int _readU32(Uint8List data, int offset) {
  return ByteData.sublistView(data, offset, offset + 4).getUint32(0, Endian.big);
}

Uint8List _concat(List<List<int>> parts) {
  final builder = BytesBuilder();
  for (final part in parts) {
    builder.add(part);
  }
  return builder.toBytes();
}
