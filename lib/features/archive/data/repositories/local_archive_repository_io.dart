import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_explorer/features/archive/domain/entities/archive_entry.dart';
import 'package:file_explorer/features/archive/domain/repositories/archive_repository.dart';
import 'package:file_explorer/shared/archive/archive_format.dart';

class LocalArchiveRepository implements ArchiveRepository {
  const LocalArchiveRepository();

  @override
  Future<ArchiveListing> listDirectory(
    String archivePath, {
    String directoryPath = '',
  }) async {
    final format = archiveFormatForPath(archivePath);
    if (format == null || !isBrowsableArchive(format)) {
      throw FileSystemException('Unsupported archive format', archivePath);
    }
    if (format == ArchiveFormat.gzip) {
      return ArchiveListing(
        archivePath: archivePath,
        directoryPath: directoryPath,
        entries: _entriesForGzip(archivePath),
      );
    }
    final archive = _decodeArchive(archivePath);
    return ArchiveListing(
      archivePath: archivePath,
      directoryPath: directoryPath,
      entries: _entriesForDirectory(archive, directoryPath),
    );
  }

  @override
  Future<Uint8List?> readEntry(String archivePath, String entryPath) async {
    final format = archiveFormatForPath(archivePath);
    if (format == null || !isBrowsableArchive(format)) {
      throw FileSystemException('Unsupported archive format', archivePath);
    }
    if (format == ArchiveFormat.gzip) {
      if (_normalizeName(entryPath) != archiveBaseName(archivePath)) {
        return null;
      }
      return const GZipDecoder()
          .decodeBytes(File(archivePath).readAsBytesSync());
    }
    final archive = _decodeArchive(archivePath);
    final normalized = _normalizeName(entryPath);
    for (final file in archive) {
      if (file.isFile && _normalizeName(file.name) == normalized) {
        return file.readBytes();
      }
    }
    return null;
  }

  List<ArchiveEntry> _entriesForGzip(String archivePath) {
    final name = archiveBaseName(archivePath);
    final decompressed =
        const GZipDecoder().decodeBytes(File(archivePath).readAsBytesSync());
    return [
      ArchiveEntry(
        name: name,
        path: name,
        isFolder: false,
        sizeBytes: decompressed.length,
        modifiedAt: File(archivePath).lastModifiedSync(),
      ),
    ];
  }

  Archive _decodeArchive(String archivePath) {
    final format = archiveFormatForPath(archivePath);
    if (format == null || format == ArchiveFormat.gzip) {
      throw FileSystemException('Unsupported archive format', archivePath);
    }
    return switch (format) {
      ArchiveFormat.zip =>
        ZipDecoder().decodeStream(InputFileStream(archivePath)),
      ArchiveFormat.tar ||
      ArchiveFormat.tarGzip ||
      ArchiveFormat.tarBzip2 ||
      ArchiveFormat.tarXz =>
        TarDecoder().decodeBytes(_decompressedTarBytes(archivePath, format)),
      ArchiveFormat.gzip => throw FileSystemException(
          'Unsupported archive format',
          archivePath,
        ),
    };
  }

  Uint8List _decompressedTarBytes(String archivePath, ArchiveFormat format) {
    switch (format) {
      case ArchiveFormat.tarGzip:
        return const GZipDecoder()
            .decodeBytes(File(archivePath).readAsBytesSync());
      case ArchiveFormat.tarBzip2:
        return BZip2Decoder().decodeBytes(File(archivePath).readAsBytesSync());
      case ArchiveFormat.tarXz:
        return XZDecoder().decodeBytes(File(archivePath).readAsBytesSync());
      default:
        return File(archivePath).readAsBytesSync();
    }
  }

  List<ArchiveEntry> _entriesForDirectory(
      Archive archive, String directoryPath) {
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

    final children = <String, ArchiveEntry>{};
    final dirDepth =
        normalizedDir.isEmpty ? 0 : normalizedDir.split('/').length;
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
          children[childName] = ArchiveEntry(
            name: childName,
            path: '$prefix$childName',
            isFolder: true,
            modifiedAt: existing.modifiedAt,
            childrenCount: folderCounts['$prefix$childName'],
          );
        }
        continue;
      }

      children[childName] = ArchiveEntry(
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

  int _compareEntries(ArchiveEntry left, ArchiveEntry right) {
    if (left.isFolder != right.isFolder) {
      return left.isFolder ? -1 : 1;
    }
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  }
}

ArchiveRepository createArchiveRepository() {
  return const LocalArchiveRepository();
}
