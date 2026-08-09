import 'dart:typed_data';

import 'package:file_explorer/features/archive/domain/entities/archive_entry.dart';
import 'package:file_explorer/features/archive/domain/repositories/archive_repository.dart';
import 'package:file_explorer/features/explorer/data/repositories/fake_storage_repository.dart';

class FakeArchiveRepository implements ArchiveRepository {
  const FakeArchiveRepository();

  static const sampleArchivePath =
      '${FakeStorageRepository.rootPath}/Download/Archive_backup.zip';

  @override
  Future<ArchiveListing> listDirectory(
    String archivePath, {
    String directoryPath = '',
  }) async {
    return ArchiveListing(
      archivePath: archivePath,
      directoryPath: directoryPath,
      entries: _entriesFor(directoryPath),
    );
  }

  @override
  Future<Uint8List?> readEntry(String archivePath, String entryPath) async {
    if (entryPath == 'Documents/notes.txt') {
      return Uint8List.fromList('hello from zip'.codeUnits);
    }
    if (entryPath == 'backup_manifest.json') {
      return Uint8List.fromList('{"version": 1}'.codeUnits);
    }
    if (entryPath.endsWith('.jpg') || entryPath.endsWith('.png')) {
      return Uint8List.fromList(_sampleImageBytes);
    }
    return null;
  }

  List<ArchiveEntry> _entriesFor(String directoryPath) {
    final now = DateTime.now();
    switch (directoryPath) {
      case '':
        return [
          ArchiveEntry(
            name: 'Documents',
            path: 'Documents',
            isFolder: true,
            childrenCount: 3,
            modifiedAt: now.subtract(const Duration(days: 2)),
          ),
          ArchiveEntry(
            name: 'Photos',
            path: 'Photos',
            isFolder: true,
            childrenCount: 2,
            modifiedAt: now.subtract(const Duration(days: 1)),
          ),
          ArchiveEntry(
            name: 'backup_manifest.json',
            path: 'backup_manifest.json',
            isFolder: false,
            sizeBytes: 2048,
            modifiedAt: now,
          ),
        ];
      case 'Documents':
        return [
          ArchiveEntry(
            name: 'Invoice_Q3.pdf',
            path: 'Documents/Invoice_Q3.pdf',
            isFolder: false,
            sizeBytes: 2 * 1024 * 1024,
            modifiedAt: now.subtract(const Duration(days: 1)),
          ),
          ArchiveEntry(
            name: 'notes.txt',
            path: 'Documents/notes.txt',
            isFolder: false,
            sizeBytes: 24 * 1024,
            modifiedAt: now,
          ),
          ArchiveEntry(
            name: 'Spreadsheet.xlsx',
            path: 'Documents/Spreadsheet.xlsx',
            isFolder: false,
            sizeBytes: 96 * 1024,
            modifiedAt: now.subtract(const Duration(days: 2)),
          ),
        ];
      case 'Photos':
        return [
          ArchiveEntry(
            name: 'IMG_20260730.jpg',
            path: 'Photos/IMG_20260730.jpg',
            isFolder: false,
            sizeBytes: 4 * 1024 * 1024,
            modifiedAt: now.subtract(const Duration(hours: 3)),
          ),
          ArchiveEntry(
            name: 'Screenshot.png',
            path: 'Photos/Screenshot.png',
            isFolder: false,
            sizeBytes: 2 * 1024 * 1024,
            modifiedAt: now.subtract(const Duration(hours: 5)),
          ),
        ];
      default:
        return const [];
    }
  }
}

ArchiveRepository createArchiveRepository() {
  return const FakeArchiveRepository();
}

const _sampleImageBytes = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];