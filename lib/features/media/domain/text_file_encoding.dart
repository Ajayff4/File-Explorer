import 'dart:convert';
import 'dart:typed_data';

enum TextFileEncoding {
  utf8('UTF-8'),
  latin1('Latin-1'),
  utf16le('UTF-16 LE'),
  utf16be('UTF-16 BE');

  const TextFileEncoding(this.label);

  final String label;

  bool get isUtf16 =>
      this == TextFileEncoding.utf16le || this == TextFileEncoding.utf16be;

  bool get supportsBom => this != TextFileEncoding.latin1;
}

class DecodedTextFile {
  const DecodedTextFile({
    required this.text,
    required this.encoding,
    required this.hasBom,
  });

  final String text;
  final TextFileEncoding encoding;
  final bool hasBom;
}

DecodedTextFile decodeTextFile(
  Uint8List bytes, {
  TextFileEncoding? encoding,
}) {
  final bomEncoding = _encodingForBom(bytes);
  final effectiveEncoding = encoding ?? bomEncoding ?? _fallbackEncoding(bytes);
  final hasBom = bomEncoding == effectiveEncoding;
  final body = hasBom
      ? bytes.sublist(
          effectiveEncoding == TextFileEncoding.utf8 ? 3 : 2,
        )
      : bytes;

  final text = switch (effectiveEncoding) {
    TextFileEncoding.utf8 => utf8.decode(body),
    TextFileEncoding.latin1 => latin1.decode(body),
    TextFileEncoding.utf16le => _decodeUtf16(body, Endian.little),
    TextFileEncoding.utf16be => _decodeUtf16(body, Endian.big),
  };

  return DecodedTextFile(
    text: text,
    encoding: effectiveEncoding,
    hasBom: hasBom,
  );
}

Uint8List encodeTextFile(
  String text, {
  required TextFileEncoding encoding,
  bool withBom = false,
}) {
  final addBom = withBom && encoding.supportsBom;
  switch (encoding) {
    case TextFileEncoding.utf8:
      final encoded = utf8.encode(text);
      if (!addBom) {
        return Uint8List.fromList(encoded);
      }
      return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...encoded]);
    case TextFileEncoding.latin1:
      return Uint8List.fromList(latin1.encode(text));
    case TextFileEncoding.utf16le:
      return _encodeUtf16(text, Endian.little, withBom: addBom);
    case TextFileEncoding.utf16be:
      return _encodeUtf16(text, Endian.big, withBom: addBom);
  }
}

TextFileEncoding? _encodingForBom(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return TextFileEncoding.utf8;
  }
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    return TextFileEncoding.utf16le;
  }
  if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
    return TextFileEncoding.utf16be;
  }
  return null;
}

TextFileEncoding _fallbackEncoding(Uint8List bytes) {
  try {
    utf8.decode(bytes);
    return TextFileEncoding.utf8;
  } on FormatException {
    return TextFileEncoding.latin1;
  }
}

String _decodeUtf16(Uint8List bytes, Endian endian) {
  if (bytes.length.isOdd) {
    throw const FormatException('Invalid UTF-16 data');
  }
  final data = ByteData.sublistView(bytes);
  final codeUnits = List<int>.generate(
    bytes.length ~/ 2,
    (index) => data.getUint16(index * 2, endian),
  );
  return String.fromCharCodes(codeUnits);
}

Uint8List _encodeUtf16(
  String text,
  Endian endian, {
  required bool withBom,
}) {
  final codeUnits = text.codeUnits;
  final bomLength = withBom ? 2 : 0;
  final bytes = Uint8List(bomLength + codeUnits.length * 2);
  if (withBom) {
    bytes[0] = endian == Endian.little ? 0xFF : 0xFE;
    bytes[1] = endian == Endian.little ? 0xFE : 0xFF;
  }
  final data = ByteData.sublistView(bytes);
  for (var index = 0; index < codeUnits.length; index++) {
    data.setUint16(bomLength + index * 2, codeUnits[index], endian);
  }
  return bytes;
}
