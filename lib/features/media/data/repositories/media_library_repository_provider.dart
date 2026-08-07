import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/media/data/platform/media_store_platform.dart';
import 'package:file_explorer/features/media/data/repositories/media_library_repository_factory_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/media/data/repositories/media_library_repository_factory_io.dart';
import 'package:file_explorer/features/media/data/repositories/media_library_walk_cache.dart';
import 'package:file_explorer/features/media/domain/repositories/media_library_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mediaLibraryWalkCacheProvider = Provider<MediaLibraryWalkCache>((ref) {
  return MediaLibraryWalkCache(
    storageRepository: ref.watch(storageRepositoryProvider),
  );
});

final mediaLibraryRepositoryProvider = Provider<MediaLibraryRepository>((ref) {
  return createMediaLibraryRepository(
    ref.watch(storageRepositoryProvider),
    ref.watch(mediaLibraryWalkCacheProvider),
  );
});

/// Android-only MediaStore bridge; null elsewhere and in tests.
final mediaStorePlatformProvider = Provider<MediaStorePlatform?>((ref) {
  return createMediaStorePlatform();
});
