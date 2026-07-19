import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';

abstract interface class StorageRepository {
  Future<List<StorageVolume>> getStorageVolumes();

  Future<StorageSummary> getPrimaryStorageSummary();

  Future<DirectoryListing> listDirectory(String path);
}
