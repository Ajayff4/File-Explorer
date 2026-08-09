import 'dart:typed_data';

import 'package:file_explorer/features/zip/domain/entities/zip_entry.dart';

abstract interface class ZipRepository {
  Future<ZipListing> listDirectory(String archivePath,
      {String directoryPath = ''});

  Future<Uint8List?> readEntry(String archivePath, String entryPath);
}
