import 'package:file_explorer/features/explorer/data/repositories/local_storage_repository_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/explorer/data/repositories/local_storage_repository_io.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return createStorageRepository();
});
