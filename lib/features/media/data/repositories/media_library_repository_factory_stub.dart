import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/media/data/platform/media_store_platform.dart';
import 'package:file_explorer/features/media/data/repositories/media_library_walk_cache.dart';
import 'package:file_explorer/features/media/data/repositories/storage_media_library_repository.dart';
import 'package:file_explorer/features/media/domain/repositories/media_library_repository.dart';

MediaLibraryRepository createMediaLibraryRepository(
  StorageRepository storageRepository,
  MediaLibraryWalkCache walkCache,
) {
  return StorageMediaLibraryRepository(
    storageRepository,
    walkCache: walkCache,
  );
}

/// Returns a MediaStore platform bridge on Android, null elsewhere.
MediaStorePlatform? createMediaStorePlatform() {
  return null;
}
