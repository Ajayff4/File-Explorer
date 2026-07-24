import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';

abstract interface class StorageRepository {
  Future<List<StorageVolume>> getStorageVolumes();

  Future<StorageSummary> getPrimaryStorageSummary();

  Future<DirectoryListing> listDirectory(String path);

  /// Count entries by type recursively from a root path.
  /// Returns a map of FileSystemEntryType to count.
  Future<Map<FileSystemEntryType, int>> countEntriesByType(String rootPath);
}
