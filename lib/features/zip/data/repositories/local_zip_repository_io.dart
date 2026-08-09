import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_explorer/features/zip/domain/entities/zip_entry.dart';
import 'package:file_explorer/features/zip/domain/repositories/zip_repository.dart';

class LocalZipRepository implements ZipRepository {
  const LocalZipRepository();

  @override
  Future<ZipListing> listDirectory(
    String archivePath, {
    String directoryPath = '',
  }) async {
    final input = InputFileStream(archivePath);
    try {
      final archive = ZipDecoder().decodeStream(input);
      return ZipListing(
        archivePath: archivePath,
        directoryPath: directoryPath,
        entries: _entriesForDirectory(archive, directoryPath),
      );
    } finally {
      input.closeSync();
    }
  }

  @override
  Future<Uint8List?> readEntry(String archivePath, String entryPath) async {
    final input = InputFileStream(archivePath);
    try {
      final archive = ZipDecoder().decodeStream(input);
      final normalized = _normalizeName(entryPath);
      for (final file in archive) {
        if (file.isFile && _normalizeName(file.name) == normalized) {
          return file.readBytes();
        }
      }
      return null;
    } finally {
      input.closeSync();
    }
  }

  List<ZipEntry> _entriesForDirectory(Archive archive, String directoryPath) {
    final normalizedDir = _normalizeName(directoryPath);
    final prefix = normalizedDir.isEmpty ? '' : '$normalizedDir/';

    final folderCounts = <String, int>{};
    for (final file in archive) {
      final parts = _pathParts(file.name);
      for (var i = 0; i < parts.length; i++) {
        final folderPath = parts.sublist(0, i + 1).join('/');
        folderCounts[folderPath] = (folderCounts[folderPath] ?? 0) + 1;
      }
    }

    final children = <String, ZipEntry>{};
    final dirDepth = normalizedDir.isEmpty ? 0 : normalizedDir.split('/').length;
    for (final file in archive) {
      final parts = _pathParts(file.name);
      if (parts.isEmpty) {
        continue;
      }
      final fullPath = parts.join('/');
      if (fullPath == normalizedDir) {
        continue;
      }
      if (!fullPath.startsWith(prefix)) {
        continue;
      }
      final childName = parts[dirDepth];
      final isFolder = parts.length > dirDepth + 1 || file.isDirectory;

      final existing = children[childName];
      if (existing != null) {
        if (isFolder && !existing.isFolder) {
          children[childName] = ZipEntry(
            name: childName,
            path: '$prefix$childName',
            isFolder: true,
            modifiedAt: existing.modifiedAt,
            childrenCount: folderCounts['$prefix$childName'],
          );
        }
        continue;
      }

      children[childName] = ZipEntry(
        name: childName,
        path: '$prefix$childName',
        isFolder: isFolder,
        sizeBytes: isFolder ? null : file.size,
        modifiedAt: file.lastModDateTime,
        childrenCount: isFolder ? folderCounts['$prefix$childName'] : null,
      );
    }

    final entries = children.values.toList();
    entries.sort(_compareEntries);
    return entries;
  }

  List<String> _pathParts(String name) {
    return _normalizeName(name)
        .split('/')
        .where((part) => part.isNotEmpty)
        .toList();
  }

  String _normalizeName(String name) {
    var normalized = name.replaceAll('\\', '/');
    while (normalized.startsWith('./')) {
      normalized = normalized.substring(2);
    }
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  int _compareEntries(ZipEntry left, ZipEntry right) {
    if (left.isFolder != right.isFolder) {
      return left.isFolder ? -1 : 1;
    }
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  }
}

ZipRepository createZipRepository() {
  return const LocalZipRepository();
}
