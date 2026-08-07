import 'dart:io';

import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/media/data/platform/media_store_platform.dart';
import 'package:file_explorer/features/media/data/repositories/media_library_walk_cache.dart';
import 'package:file_explorer/features/media/data/repositories/media_store_media_library_repository.dart';
import 'package:file_explorer/features/media/data/repositories/storage_media_library_repository.dart';
import 'package:file_explorer/features/media/domain/repositories/media_library_repository.dart';

MediaLibraryRepository createMediaLibraryRepository(
  StorageRepository storageRepository,
  MediaLibraryWalkCache walkCache,
) {
  final fallback = StorageMediaLibraryRepository(
    storageRepository,
    walkCache: walkCache,
  );
  if (Platform.isAndroid) {
    return MediaStoreMediaLibraryRepository(
      platform: const MediaStorePlatform(),
      fallback: fallback,
    );
  }
  return fallback;
}

/// Returns a MediaStore platform bridge on Android, null elsewhere.
MediaStorePlatform? createMediaStorePlatform() {
  return Platform.isAndroid ? const MediaStorePlatform() : null;
}
