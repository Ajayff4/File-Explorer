import 'dart:typed_data';

import 'package:file_explorer/features/archive/domain/entities/archive_entry.dart';

abstract interface class ArchiveRepository {
  Future<ArchiveListing> listDirectory(String archivePath,
      {String directoryPath = ''});

  Future<Uint8List?> readEntry(String archivePath, String entryPath);
}