import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';

abstract interface class StorageRepository {
  Future<List<StorageVolume>> getStorageVolumes();

  Future<StorageSummary> getPrimaryStorageSummary();

  Future<DirectoryListing> listDirectory(String path);

  /// Count entries by type recursively from a root path.
  /// Returns a map of FileSystemEntryType to count.
  Future<Map<FileSystemEntryType, int>> countEntriesByType(String rootPath);

  /// Check if a folder contains files of a specific type (recursive with depth limit).
  /// Used to determine if a folder should be shown when a type filter is active.
  Future<bool> folderContainsFileType(
      String folderPath, FileSystemEntryType type);

  /// Create a new folder at the specified path.
  /// Returns true if successful, false otherwise.
  Future<bool> createFolder(String path);

  /// Create a new file at the specified path with optional initial content.
  /// Returns true if successful, false otherwise.
  Future<bool> createFile(String path, {String content = ''});
}
