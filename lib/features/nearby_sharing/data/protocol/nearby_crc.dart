/// Standard CRC-32 (IEEE 802.3, poly 0xEDB88320) used to verify file integrity
/// over the wire. Table-based for speed.
int crc32(List<int> bytes) => crc32Update(0xFFFFFFFF, bytes) ^ 0xFFFFFFFF;

/// Update a running CRC-32 with [bytes]. Start [crc] at `0xFFFFFFFF` and finish
/// with `crc ^ 0xFFFFFFFF` to get the final value. Lets callers hash a file in
/// streaming chunks instead of loading it all into memory.
int crc32Update(int crc, List<int> bytes) {
  for (final byte in bytes) {
    crc = _crc32Table[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  return crc;
}

final List<int> _crc32Table = _buildCrc32Table();

List<int> _buildCrc32Table() {
  const poly = 0xEDB88320;
  final table = List<int>.filled(256, 0);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) == 1 ? poly ^ (c >> 1) : c >> 1;
    }
    table[n] = c;
  }
  return table;
}
