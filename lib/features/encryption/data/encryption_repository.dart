import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:file_explorer/features/encryption/data/encryption_service.dart';
import 'package:path/path.dart' as p;

class EncryptionResult {
  const EncryptionResult({this.encryptedCount = 0, this.skipped = const []});

  final int encryptedCount;
  final List<String> skipped;
}

/// A single `.ff4` container found on disk.
class EncryptedFileEntry {
  const EncryptedFileEntry({
    required this.path,
    required this.name,
    required this.modifiedAt,
    this.sizeBytes,
  });

  final String path;
  final String name;
  final DateTime modifiedAt;
  final int? sizeBytes;
}

/// Recursively scans [root] for `.ff4` files, flattened into a single list.
Future<List<EncryptedFileEntry>> scanEncryptedFiles(String root) {
  return Isolate.run(() => _collectEncryptedFiles(root));
}

/// Encrypts files and folders in place: each file becomes a `.ff4` container
/// next to its original (which is deleted), preserving the folder structure.
class EncryptionRepository {
  const EncryptionRepository(this._service);

  final EncryptionService _service;

  Future<EncryptionResult> encryptPaths(
    List<String> paths, {
    required String password,
    required bool encryptName,
    void Function(String path, int bytes)? onProgress,
  }) async {
    final session = await _service.openSession(password);
    var count = 0;
    final skipped = <String>[];
    for (final path in paths) {
      count += await _encryptPath(path, session, encryptName, skipped, onProgress);
    }
    return EncryptionResult(encryptedCount: count, skipped: skipped);
  }

  /// Decrypts a `.ff4` container, writing the recovered file next to it and
  /// removing the container. Returns the path of the restored file.
  Future<String> decryptPath(String path, String password) async {
    final container = await File(path).readAsBytes();
    final decrypted = await _service.decrypt(container, password);
    final directory = p.dirname(path);
    final outputPath = _uniquePath(p.join(directory, decrypted.name));
    await File(outputPath).writeAsBytes(decrypted.bytes);
    await File(path).delete();
    return outputPath;
  }

  /// Decrypts every `.ff4` container in [paths], reporting progress per file.
  /// Returns the number of files decrypted.
  Future<int> decryptPaths(
    List<String> paths, {
    required String password,
    void Function(String path, int bytes)? onProgress,
  }) async {
    var count = 0;
    for (final path in paths) {
      if (!isEncryptedFile(path)) continue;
      final outputPath = await decryptPath(path, password);
      count++;
      final bytes = await File(outputPath).length();
      onProgress?.call(path, bytes == 0 ? 1 : bytes);
    }
    return count;
  }

  Future<int> _encryptPath(
    String path,
    EncryptionSession session,
    bool encryptName,
    List<String> skipped, [
    void Function(String path, int bytes)? onProgress,
  ]) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.directory) {
      var count = 0;
      await for (final entity
          in Directory(path).list(recursive: true, followLinks: false)) {
        if (entity is File && !isEncryptedFile(entity.path)) {
          count += await _encryptFile(entity.path, session, encryptName, skipped,
              onProgress);
        }
      }
      return count;
    }
    if (type == FileSystemEntityType.file && !isEncryptedFile(path)) {
      return _encryptFile(path, session, encryptName, skipped, onProgress);
    }
    return 0;
  }

  Future<int> _encryptFile(
    String path,
    EncryptionSession session,
    bool encryptName,
    List<String> skipped, [
    void Function(String path, int bytes)? onProgress,
  ]) async {
    try {
      final content = await File(path).readAsBytes();
      final name = p.basename(path);
      final container = await _service.encrypt(
        content,
        session,
        name,
        encryptName: encryptName,
      );
      final outputPath = _outputPathFor(path, encryptName);
      await File(outputPath).writeAsBytes(container);
      await File(path).delete();
      onProgress?.call(path, content.isEmpty ? 1 : content.length);
      return 1;
    } catch (_) {
      skipped.add(path);
      return 0;
    }
  }

  String _outputPathFor(String sourcePath, bool encryptName) {
    final directory = p.dirname(sourcePath);
    if (encryptName) {
      return _uniquePath(p.join(directory, '${_randomId()}$ff4Extension'));
    }
    return _uniquePath(p.join(directory, '${p.basename(sourcePath)}$ff4Extension'));
  }

  String _randomId() {
    final rng = Random.secure();
    return List.generate(16, (_) => rng.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String _uniquePath(String path) {
    if (!File(path).existsSync() && !Directory(path).existsSync()) {
      return path;
    }
    final directory = p.dirname(path);
    final extension = p.extension(path);
    final baseName = p.basenameWithoutExtension(path);
    var sequence = 1;
    while (true) {
      final candidate = p.join(directory, '$baseName ($sequence)$extension');
      if (!File(candidate).existsSync() && !Directory(candidate).existsSync()) {
        return candidate;
      }
      sequence += 1;
    }
  }
}

Future<List<EncryptedFileEntry>> _collectEncryptedFiles(String root) async {
  final results = <EncryptedFileEntry>[];
  await _walkEncrypted(root, results);
  results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return results;
}

Future<void> _walkEncrypted(String path, List<EncryptedFileEntry> results) async {
  try {
    await for (final entity in Directory(path).list(followLinks: false)) {
      try {
        if (entity is Directory) {
          await _walkEncrypted(entity.path, results);
        } else if (entity is File && isEncryptedFile(entity.path)) {
          final stat = await entity.stat();
          results.add(
            EncryptedFileEntry(
              path: entity.path,
              name: p.basename(entity.path),
              modifiedAt: stat.modified,
              sizeBytes: stat.size,
            ),
          );
        }
      } on FileSystemException {
        // Skip unreadable entries.
      }
    }
  } on FileSystemException {
    // Skip unreadable directories (e.g. /Android/data).
  }
}
