import 'dart:io';

import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/media/data/platform/media_store_platform.dart';
import 'package:file_explorer/features/media/data/repositories/media_store_media_library_repository.dart';
import 'package:file_explorer/features/media/data/repositories/storage_media_library_repository.dart';
import 'package:file_explorer/features/media/domain/repositories/media_library_repository.dart';

MediaLibraryRepository createMediaLibraryRepository(
  StorageRepository storageRepository,
) {
  final fallback = StorageMediaLibraryRepository(storageRepository);
  if (Platform.isAndroid) {
    return MediaStoreMediaLibraryRepository(
      platform: const MediaStorePlatform(),
      fallback: fallback,
    );
  }
  return fallback;
}
