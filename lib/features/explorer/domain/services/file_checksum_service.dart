import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;

/// Hash algorithms offered by the checksum viewer.
enum ChecksumAlgorithm {
  md5('MD5'),
  sha1('SHA-1'),
  sha256('SHA-256'),
  sha512('SHA-512');

  const ChecksumAlgorithm(this.label);

  final String label;

  crypto.Hash get hash {
    return switch (this) {
      ChecksumAlgorithm.md5 => crypto.md5,
      ChecksumAlgorithm.sha1 => crypto.sha1,
      ChecksumAlgorithm.sha256 => crypto.sha256,
      ChecksumAlgorithm.sha512 => crypto.sha512,
    };
  }
}

class FileChecksum {
  const FileChecksum({required this.algorithm, required this.digest});

  final ChecksumAlgorithm algorithm;
  final String digest;
}

/// Computes file checksums without loading the whole file into memory.
class FileChecksumService {
  const FileChecksumService();

  Future<List<FileChecksum>> compute(
    String path, {
    List<ChecksumAlgorithm> algorithms = ChecksumAlgorithm.values,
  }) async {
    final requestedAlgorithms = algorithms.toSet();
    final selectedAlgorithms = ChecksumAlgorithm.values
        .where(requestedAlgorithms.contains)
        .toList(growable: false);
    if (selectedAlgorithms.isEmpty) {
      return const [];
    }

    final collectors = {
      for (final algorithm in selectedAlgorithms) algorithm: _DigestCollector(),
    };
    final inputs = <ByteConversionSink>[
      for (final algorithm in selectedAlgorithms)
        algorithm.hash.startChunkedConversion(collectors[algorithm]!),
    ];

    await for (final chunk in File(path).openRead()) {
      for (final input in inputs) {
        input.add(chunk);
      }
    }
    for (final input in inputs) {
      input.close();
    }

    return [
      for (final algorithm in selectedAlgorithms)
        FileChecksum(
          algorithm: algorithm,
          digest: collectors[algorithm]!.digest.toString(),
        ),
    ];
  }
}

class _DigestCollector implements Sink<crypto.Digest> {
  crypto.Digest? _digest;

  crypto.Digest get digest {
    final value = _digest;
    if (value == null) {
      throw StateError('Digest was not produced');
    }
    return value;
  }

  @override
  void add(crypto.Digest data) {
    _digest = data;
  }

  @override
  void close() {}
}
