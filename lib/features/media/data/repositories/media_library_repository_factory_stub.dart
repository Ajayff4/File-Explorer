import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:file_explorer/features/media/data/repositories/storage_media_library_repository.dart';
import 'package:file_explorer/features/media/domain/repositories/media_library_repository.dart';

MediaLibraryRepository createMediaLibraryRepository(
  StorageRepository storageRepository,
) {
  return StorageMediaLibraryRepository(storageRepository);
}
