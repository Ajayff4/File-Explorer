import 'dart:io';

import 'package:file_explorer/features/explorer/domain/services/file_checksum_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = FileChecksumService();
  late Directory tempDirectory;
  late File file;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('checksum_test_');
    file = File('${tempDirectory.path}/sample.txt');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('computes all supported checksums in one pass', () async {
    await file.writeAsString('abc');

    final checksums = await service.compute(file.path);

    expect(checksums, hasLength(4));
    expect(
      {for (final checksum in checksums) checksum.algorithm: checksum.digest},
      {
        ChecksumAlgorithm.md5: '900150983cd24fb0d6963f7d28e17f72',
        ChecksumAlgorithm.sha1: 'a9993e364706816aba3e25717850c26c9cd0d89d',
        ChecksumAlgorithm.sha256:
            'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
        ChecksumAlgorithm.sha512:
            'ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a'
                '2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f',
      },
    );
  });

  test('computes checksums for an empty file', () async {
    await file.writeAsBytes(const []);

    final checksums = await service.compute(
      file.path,
      algorithms: [ChecksumAlgorithm.md5, ChecksumAlgorithm.sha256],
    );

    expect(checksums, hasLength(2));
    expect(checksums[0].digest, 'd41d8cd98f00b204e9800998ecf8427e');
    expect(
      checksums[1].digest,
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
  });

  test('returns no checksums when no algorithms are selected', () async {
    await file.writeAsString('abc');

    expect(await service.compute(file.path, algorithms: const []), isEmpty);
  });

  test('streams large files', () async {
    final bytes = List<int>.generate(1024 * 1024, (index) => index % 251);
    await file.writeAsBytes(bytes);

    final checksums = await service.compute(
      file.path,
      algorithms: [ChecksumAlgorithm.sha256],
    );

    final expected = ChecksumAlgorithm.sha256.hash.convert(bytes).toString();
    expect(checksums.single.digest, expected);
  });
}
