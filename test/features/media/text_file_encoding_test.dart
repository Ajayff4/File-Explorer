import 'dart:typed_data';

import 'package:file_explorer/features/media/domain/text_file_encoding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects and strips a UTF-8 BOM', () {
    final decoded = decodeTextFile(
      Uint8List.fromList([0xEF, 0xBB, 0xBF, ...'hello'.codeUnits]),
    );

    expect(decoded.text, 'hello');
    expect(decoded.encoding, TextFileEncoding.utf8);
    expect(decoded.hasBom, isTrue);
  });

  test('detects and decodes UTF-16 little endian', () {
    final decoded = decodeTextFile(
      Uint8List.fromList([0xFF, 0xFE, 0x68, 0x00, 0x69, 0x00]),
    );

    expect(decoded.text, 'hi');
    expect(decoded.encoding, TextFileEncoding.utf16le);
    expect(decoded.hasBom, isTrue);
  });

  test('detects and decodes UTF-16 big endian', () {
    final decoded = decodeTextFile(
      Uint8List.fromList([0xFE, 0xFF, 0x00, 0x68, 0x00, 0x69]),
    );

    expect(decoded.text, 'hi');
    expect(decoded.encoding, TextFileEncoding.utf16be);
    expect(decoded.hasBom, isTrue);
  });

  test('falls back to Latin-1 for invalid UTF-8', () {
    final decoded = decodeTextFile(
      Uint8List.fromList([0x63, 0x61, 0x66, 0xE9]),
    );

    expect(decoded.text, 'café');
    expect(decoded.encoding, TextFileEncoding.latin1);
    expect(decoded.hasBom, isFalse);
  });

  test('honors a forced encoding', () {
    final decoded = decodeTextFile(
      Uint8List.fromList([0x68, 0x00, 0x69, 0x00]),
      encoding: TextFileEncoding.utf16le,
    );

    expect(decoded.text, 'hi');
    expect(decoded.hasBom, isFalse);
  });

  test('encodes UTF-16 with a matching BOM', () {
    final bytes = encodeTextFile(
      'hi',
      encoding: TextFileEncoding.utf16le,
      withBom: true,
    );

    expect(bytes, [0xFF, 0xFE, 0x68, 0x00, 0x69, 0x00]);
    expect(
      decodeTextFile(bytes).text,
      'hi',
    );
  });

  test('round trips unicode text through every encoding', () {
    const text = 'café — 東京';
    for (final encoding in TextFileEncoding.values) {
      if (encoding == TextFileEncoding.latin1) {
        continue;
      }
      final bytes = encodeTextFile(
        text,
        encoding: encoding,
        withBom: true,
      );
      expect(decodeTextFile(bytes).text, text, reason: encoding.label);
    }
  });

  test('rejects malformed UTF-16 data', () {
    expect(
      () => decodeTextFile(
        Uint8List.fromList([0x68, 0x00, 0x69]),
        encoding: TextFileEncoding.utf16le,
      ),
      throwsFormatException,
    );
  });
}
